---
layout: post
categories: [bash]
keywords: []
---

When writing shell scripts invoked by udev rules, I almost always use the
following template:

```shell
#!/usr/bin/env bash
set -euo pipefail

CMD="`basename "${0:-udevscript}"`"
exec 1> >(logger -t "${CMD}")
exec 2> >(ts '[stderr]' | logger -t "${CMD}")

DEBUG="${1:-false}"
if [ "${DEBUG}" = true ]; then set -x; fi

echo "running: ${0}"
env

# Actual script starts here
```

We can then use such a script in a udev rule like this:

```shell
SUBSYSTEM=="usb", \
  ACTION=="remove", \
  ENV{ID_VENDOR_ID}=="17e9", \
  ENV{ID_MODEL_ID}=="6015", \
  RUN+="/usr/lib/udev/scripts/undock.sh"
```

When the udev rule runs the script, everything printed is appended to the system
log. Stderr messages will be prefixed with `[stderr]`. Checking what your script
does is then as simple as:

```shell
$ journalctl -e -t undock.sh
Oct 25 22:58:35 puddle undock.sh[32366]: running: /usr/lib/udev/scripts/undock.sh
Oct 25 22:58:35 puddle undock.sh[32366]: ID_SERIAL=DisplayLink_ThinkPad_Hybrid_USB-C_with_USB-A_Dock_10391787
Oct 25 22:58:35 puddle undock.sh[32366]: ID_MODEL_ID=6015
Oct 25 22:58:35 puddle undock.sh[32366]: ACTION=remove
...
```

The template also supports debug output. Setting the first argument to `true`
will print commands and their arguments as they are executed to stderr.
