---
layout: post
categories: [evkill, bash]
title: Disable reMarkable Touchscreen with evkill
image: /static/posts/disable-reMarkable-touchscreen-with-evkill/evkill.png
keywords: [evdev, evkill, reMarkable, disable touchscreen]
---

[`evkill`][evkill] is a silencer for evdev input devices. Run a single command and make
your `/dev/input/` devices go "psst!".  In this post we will use `evkill` on a
reMarkable e-ink writing tablet to disable the capacitive display while writing.

![evkill on reMarkable](/static/posts/disable-reMarkable-touchscreen-with-evkill/evkill.png)

## The Problem

Since reMarkable has introduced page flips using swipe gestures, it happens a
lot that I unintentionally change page while writing. They must have put some
detection for this into their software, but for whatever reason this does not
work for me on my device [^1]. This is why I would like to be able to disable the
capcitive sensor behind the screen by a button press. [In a previous post I
already showed how we can toggle flight mode with the hardware
buttons][reMarkable-hacking]. This time we will reuse the same script. But
instead of switching network devices on and off, we will use [`evkill`][evkill]
to disable input devices.

## The Hack

First, we download the [`evkill`][evkill] armv7l build and upload the executable
to the reMarkable.

```sh
$ curl https://raw.githubusercontent.com/Enteee/evkill/master/install.sh | ARCH="armv7l" sh
$ scp evkill root@10.11.99.1:.
```

Next, we cross compile and upload [`evtest`][evtest].

```sh
$ git clone https://github.com/freedesktop-unofficial-mirror/evtest.git
$ cd evtest
$ docker \
  run --rm \
  dockcross/linux-armv7a > dockercross
$ chmod +x dockercross
$ ./dockercross bash -c "autoreconf -iv && ./configure --host=arm-linux-gnueabi && make"
$ scp evtest root@10.11.99.1:.
```

Given the device mapping from the table below, we adapt the script from [the
previous post][reMarkable-hacking].

{:.table}
| Device | Name | Description |
| ------ | ---- | ----------- |
| `/dev/input/event0` | Wacom I2C Digitizer | The capacitive pen input device |
| `/dev/input/event1` | cyttsp5_mt | The touchscreen |
| `/dev/input/event2` | gpio-keys | The hardware buttons |

The idea is that the script detects button presses by listening on
`/dev/input/event2` using [`evtest`][evtest]. Once it registers a button press
from the left and right hardware button it will start an [`evkill`][evkill]
process in the background and disable `/dev/input/event1`. If we then again
press both buttons, the script will terminate all running [`evkill`][evkill]
instances with the effect of enabling the touchscreen again.

```sh
#!/usr/bin/env bash
set -euo pipefail

DEVICE_BUTTONS='/dev/input/event2'
DEVICE_TO_KILL='/dev/input/event1'

# commands
EVTEST=$(command -v evtest || echo './evtest')
EVKILL=$(command -v evkill || echo './evkill')

LEFT_DOWN=false
RIGHT_DOWN=false

toggle_evkill(){
  local evkill_pid
  evkill_pid="$(pidof evkill || true)"
  if [ -z "${evkill_pid}" ]; then
    echo "=> Disable touchscreen: ${EVKILL} ${DEVICE_TO_KILL}"
    "${EVKILL}" "${DEVICE_TO_KILL}" &
  else
    echo "=> Enable touchscreen: kill ${evkill_pid}"
    kill "${evkill_pid}" &>/dev/null
  fi
}

handle_events(){
  local key_left_down
  key_left_down='*type 1 (EV_KEY), code 105 (KEY_LEFT), value 1*'

  local key_left_up
  key_left_up='*type 1 (EV_KEY), code 105 (KEY_LEFT), value 0*'

  local key_right_down
  key_right_down='*type 1 (EV_KEY), code 106 (KEY_RIGHT), value 1*'

  local key_right_up
  key_right_up='*type 1 (EV_KEY), code 106 (KEY_RIGHT), value 0*'


  "$EVTEST" "$DEVICE_BUTTONS" | while read -r line; do
      case $line in
          ($key_left_down) LEFT_DOWN=true ;;
          ($key_left_up) LEFT_DOWN=false ;;
          ($key_right_down) RIGHT_DOWN=true ;;
          ($key_right_up) RIGHT_DOWN=false ;;
          (*) continue ;;
      esac
      echo "$line -> LEFT ${LEFT_DOWN} , RIGHT: ${RIGHT_DOWN}"

      if [ "${LEFT_DOWN}" = true ] && [ "${RIGHT_DOWN}" = true ]; then
        toggle_evkill
      fi
  done
}

handle_events
```

If we now save the script to an executable file called `disable-touchscreen.sh`
and run it on the device, we have achieved what we wanted.

```sh
$ chmod +x disable-touchscreen.sh
$ scp disable-touchscreen.sh root@10.11.99.1:.
$ ssh -t -t root@10.11.99.1 ./disable-touchscreen.sh
```

**Important**: In case you omit the `-t -t` options to `ssh`, the script will
keep running on the reMarkable even after you exit ssh with CRTL+C. This might
cause some problems when the devices activates the lock screen.

Below a demonstration of how this looks like on an actual reMarkable:

<div class="embed-responsive embed-responsive-4by3">
  <iframe
    width="560"
    height="315"
    src="https://www.youtube.com/embed/skB0LoFMXNs"
    frameborder="0"
    allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen
  ></iframe>
</div>

[^1]: Version 2.2.0.48

[evkill]:https://github.com/Enteee/evkill
[evtest]:https://github.com/freedesktop-unofficial-mirror/evtest
[reMarkable-hacking]:/nix/bash/2020/01/08/reMarkable
