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
- The graveyard queue also has a delivery limit, after which tasks go to a final **dead queue**.

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

The task base class inspects RabbitMQ's `x-death` headers to determine how many times a message has been dead-lettered. When the task sees multiple `x-death` entries, it is flagged as permanently dead and skipped.

```python
class BaseTask(Task):
    def __call__(self, *args, **kwargs):
        x_death = self.request.headers.get("x-death", [])
        if len(x_death) > 1:
            raise DeadTask("This task has already been reaped.")
        return self.run(*args, **kwargs)
```

## Why It Works

This architecture isolates failure from progress. Reaper workers handle the worst-case tasks without contaminating the main processing pool. Delivery limits and explicit dead letter queues prevent infinite retries. The one-queue-per-task model ensures fair scheduling, and now with dead-lettering, also ensures robustness under failure.

With this change, a single poison task no longer halts the system. Failures become visible, bounded, and isolated - the way they should be.
