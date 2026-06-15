---
layout: post
categories: [python]
image: /static/posts/reaping-poison-tasks-in-celery/task-queues.png
keywords: [celery, python, dead letter queues, rabbitmq]
---

Celery pipelines often work fine until one task brings everything to a halt. For us, the root cause was simple: when Kubernetes OOM-killed a Celery worker during execution, RabbitMQ would redeliver the unacknowledged task. In practice, this meant the same poison task (often memory-intensive) would bounce from worker to worker, gradually stalling the entire pipeline.

## Task Queue Architecture

Our setup uses a **one-queue-per-task-type** model. Every Celery task is routed to its own RabbitMQ queue. This design ensures:

- All tasks are treated with equal priority
- Workers can subscribe to all tasks without any implicit weighting

The task-to-queue mapping is created dynamically at startup:

```python
for task_name in app.tasks.keys():
    queue_name = f"celery:{task_name}"
    task_queues.append(Queue(queue_name, ...))
    task_routes[task_name] = {"queue": queue_name}
```

However, there's a catch. Even with `worker_prefetch_multiplier=1`, Celery fetches one task per queue. If a worker listens to 100 queues, it may prefetch 100 tasks at once. When that worker is OOM-killed, all prefetched but unacknowledged tasks are redelivered, each with their delivery count incremented.

This results in two problems:

1. Poison tasks cause repeated worker crashes and restarts.
2. Healthy tasks also get redelivered unnecessarily, increasing delivery counts and wasting processing time.

## Introducing Dead Letter Queues

To make task failure explicit and avoid stalling the pipeline, we introduced RabbitMQ Quorum Queues with `x-delivery-limit` and dead-lettering. The model now looks like this:

- Each task-specific queue is a quorum queue with a delivery limit.
- On reaching the delivery limit, tasks are routed to a **graveyard queue**.
- The graveyard queue also has a delivery limit, after which tasks go to a **dead queue**.
- The dead queue also has a delivery limit, after which tasks go to a final **abyss queue** — from which no worker ever consumes.

![dead letter queues](/static/posts/reaping-poison-tasks-in-celery/task-queues.svg){: .stretch }

This setup ensures that poison tasks are automatically redirected out of the main processing flow.

## Reaper Workers

To process the graveyard and dead queues, we introduced a dedicated class of workers:

- They **only subscribe to the graveyard and dead queues**.
- They run with **worker\_concurrency=1** and **worker\_prefetch\_multiplier=1**.
- Graveyard tasks are re-executed in isolation - one at a time.
- Dead queue tasks are never executed. They are skipped by immediately raising an exception.

This isolation is essential: the reaper worker only prefetches a single task from the graveyard, and because it subscribes to no other queues, there is no chance of delivery count pollution from co-scheduled tasks.

This design has several advantages:

- Poison tasks no longer interfere with normal task execution.
- Dead-lettering is now a first-class concept.
- Tasks that exceed retry limits become visible failures, not silent stalls.

The task base class inspects RabbitMQ's `x-death` headers to detect whether a task has already been through graveyard processing. If the graveyard queue appears in the `x-death` entries, the task is flagged as permanently dead and skipped immediately.

```python
_NDL_ROUTING_KEY_RE = re.compile(r"^[01](?:\.[01]){27}\.(.+)$")

class BaseTask(Task):
    def __call__(self, *args, **kwargs):
        headers = getattr(self.request, "headers", {}) or {}

        x_death = XDeathHeader.model_validate(headers.get("x-death", []))

        headers.pop("x-death", None)
        x_death = XDeathHeader(
            root=[d for d in x_death.root if not d.queue.startswith("celery_delayed")]
        )

        delivery_info = getattr(self.request, "delivery_info", {}) or {}
        if m := _NDL_ROUTING_KEY_RE.match(delivery_info.get("routing_key", "")):
            delivery_info["routing_key"] = m.group(1)

        graveyard_queue = "celery:graveyard"
        if any(d.queue == graveyard_queue for d in x_death.root):
            raise DeadTask(f"Task died: {x_death}")
        return self.run(*args, **kwargs)
```

There is more going on here than just the graveyard check. Two additional bugs lurk in the interaction between `autoretry_for` and Native Delayed Delivery — both fixed in `__call__`.

### A subtle gotcha: don't count `x-death` entries

An earlier version of this check simply counted `x-death` entries and raised `DeadTask` when there were more than one:

```python
if len(x_death) > 1:
    raise DeadTask(...)
```

This turns out to be wrong once you enable `worker_detect_quorum_queues = True` in Celery 5.5+. That setting activates **Native Delayed Delivery** for all countdown and ETA tasks: instead of embedding the ETA in the message, Celery routes the message through a binary cascade of TTL queues (`celery_delayed_0`, `celery_delayed_1`, …). Each TTL queue appends its own `x-death` entry as the message expires and is forwarded.

A countdown of 3 seconds is encoded as binary `11`, meaning the message passes through `celery_delayed_0` (1 s TTL) and then `celery_delayed_1` (2 s TTL) before reaching the destination queue — arriving with **two** `x-death` entries. The count-based check would therefore kill every task whose retry delay has more than one bit set in its binary representation.

Checking for the graveyard queue by name is precise: it fires exactly when the task has been through graveyard processing, regardless of how many delayed-delivery TTL hops the message took to get there.

### A subtle gotcha: OOM during deserialization in the dead queue

The reaper raises `DeadTask` after successfully deserializing a dead-queue message and inspecting its `x-death` headers. But what if the reaper is OOM-killed *during deserialization*, before `__call__` is ever reached?

With `task_acks_late = True`, no acknowledgement is sent. RabbitMQ re-enqueues the message and increments its delivery count. If the dead queue has no `x-delivery-limit` — which was the case when it was the terminal stop — this becomes a permanent trap: the reaper keeps picking up the message, OOM-killing itself, and restarting, indefinitely.

The fix is to give the dead queue its own delivery limit and a dead-letter destination that no process consumes — the **abyss queue**:

```python
# dead queue
queue_arguments={
    "x-queue-type": "quorum",
    "x-delivery-limit": 3,
    "x-dead-letter-exchange": "tasks",
    "x-dead-letter-routing-key": "abyss",
}

# abyss queue
queue_arguments={
    "x-queue-type": "quorum",
    "x-message-ttl": 7 * 24 * 60 * 60 * 1000,  # 7 days in ms
}
```

The abyss queue is declared with only an `x-message-ttl`. No worker, persister, or reaper subscribes to it. Messages that land there expire quietly after the configured TTL.

When deserialization succeeds and `DeadTask` is raised normally, the task is acknowledged (`task_acks_on_failure_or_timeout = True`), so the delivery count does not increment and the message is removed. The delivery limit only triggers on unacknowledged redeliveries — precisely the OOM-kill scenario.

### A subtle gotcha: `x-death` accumulates inside `autoretry_for` retry chains

Celery's `retry()` constructs the next retry message by copying `self.request.headers` verbatim. That copy includes the `x-death` header RabbitMQ set when the message was dead-lettered out of a TTL queue. With Native Delayed Delivery, every NDL round-trip appends a fresh `celery_delayed_N` entry to `x-death`.

After enough retries the accumulated `x-death` header grows large, and — depending on RabbitMQ version and queue policy — can cause the broker to treat the message as having exhausted its delivery budget and route it to the graveyard before `max_retries` is reached.

The fix is to strip `x-death` from `headers` in `__call__` before `run()` is called, so that `retry()` always publishes a clean message. It is safe to remove `x-death` entirely: RabbitMQ ignores any `x-death` present on a published message and writes its own fresh value on dead-lettering.

We also filter out `celery_delayed_*` entries before the graveyard check, because those entries are an NDL artefact and should not influence whether a task is considered permanently dead:

```python
headers.pop("x-death", None)
x_death = XDeathHeader(
    root=[d for d in x_death.root if not d.queue.startswith("celery_delayed")]
)
```

### A subtle gotcha: the NDL routing key grows with every retry

This one caused `struct.error: 'B' format requires 0 <= number <= 255` — AMQP's hard limit on routing key length — and took a while to track down.

When Celery publishes a retry via Native Delayed Delivery, it computes a new routing key by prepending a 56-character binary prefix to the original routing key:

```python
# kombu/transport/native_delayed_delivery.py
return '.'.join(list(f'{countdown:028b}')) + f'.{routing_key}'
# e.g. countdown=1 → "0.0.0.…0.0.1.<original_routing_key>"
#                        ^^^^^^^^55 chars^^^^^^^^
```

The problem: `retry()` calls `signature_from_request()`, which populates the next retry's options with `delivery_info` via `options.update(delivery_info)`. Because `delivery_info['routing_key']` still contains the NDL-prefixed key from the *current* delivery, `celery/app/base.py` then calls `calculate_routing_key()` on an already-prefixed key — prepending another 56-character prefix on top.

Each retry adds 56 characters:

| Retry | Routing key length |
|-------|--------------------|
| 0 (initial) | 68 chars |
| 1 | 124 chars |
| 2 | 180 chars |
| 3 | 236 chars |
| 4 | 292 chars → **struct.error** |

The task never reaches `max_retries`; it simply stops being publishable around retry 4.

The fix is to strip the NDL prefix from `delivery_info['routing_key']` in `__call__` before `run()` is called. The prefix is always exactly 28 single-bit characters separated by 27 dots (55 chars total), followed by a dot — a pattern that's easy to match and safe to remove:

```python
_NDL_ROUTING_KEY_RE = re.compile(r"^[01](?:\.[01]){27}\.(.+)$")

delivery_info = getattr(self.request, "delivery_info", {}) or {}
if m := _NDL_ROUTING_KEY_RE.match(delivery_info.get("routing_key", "")):
    delivery_info["routing_key"] = m.group(1)
```

After stripping, `signature_from_request()` copies the original routing key into the retry options, and `calculate_routing_key()` correctly applies exactly one fresh prefix — the routing key length stays constant across all retries.

## Why It Works

This architecture isolates failure from progress. Reaper workers handle the worst-case tasks without contaminating the main processing pool. Delivery limits and explicit dead letter queues prevent infinite retries — including the edge case where the reaper itself is OOM-killed before it can process a message. The abyss queue closes that final loop: any message the reaper cannot survive lands somewhere inert, and expires. The one-queue-per-task model ensures fair scheduling, and now with dead-lettering, also ensures robustness under failure.

With this change, a single poison task no longer halts the system. Failures become visible, bounded, and isolated - the way they should be.
