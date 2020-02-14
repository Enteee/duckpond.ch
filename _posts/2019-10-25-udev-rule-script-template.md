---
layout: post
title: udev Rule Script Template
categories: [bash, nix]
keywords: [udev, log, debug]
redirect_from:
  - /bash/2019/10/25/udev-rule-script-template.html
---

When writing shell scripts invoked by udev rules, I find the following template
particularly useful:

```shell
#!/usr/bin/env bash
set -euo pipefail

CMD="`basename "${0:-udevscript}"`"
exec 1> >(tee >(logger -t "${CMD}"))
exec 2> >(ts '[stderr]' | tee >(logger -t "${CMD}"))

DEBUG="${1:-false}"
if [ "${DEBUG}" = true ]; then set -x; fi

echo "running: ${0}"
env

## Actual script starts here
```

We can then use such a script in a udev rule like we always would:

```shell
SUBSYSTEM=="usb", \
  ACTION=="remove", \
  ENV{ID_VENDOR_ID}=="17e9", \
  ENV{ID_MODEL_ID}=="6015", \
  RUN+="/usr/lib/udev/scripts/undock.sh"
```

And when the rule runs the script, everything printed is sent to the system
log. Stderr messages will be prefixed with `[stderr]`. Which makes checking what
the script does as simple as:

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

## Bonus: A Nix Expression

The script above is derived from the following nix expression.

```nix
{ pkgs ? import <nixpkgs> {}, ... }:

let

  logger = "${pkgs.utillinux}/bin/logger";
  ts = "${pkgs.moreutils}/bin/ts";
  tee = "${pkgs.coreutils}/bin/tee";

in name : script: {
    strict ? true,
    log ? true,
    debug ? false,
    printenv ? true,
  }: let

    strictCmd = if strict then
      ''
      set -euo pipefail
      ''
    else "";

    logCmd = if log then
      ''
      exec 1> >(${tee} >(${logger} -t "${name}"))
      exec 2> >(${ts} '[stderr]' | ${tee} >(${logger} -t "${name}"))
      ''
    else "";

    debugCmd = if debug then
      ''
      set -x
      ''
    else "";

    printenvCmd = if printenv then
      ''
      echo "running: ${name}"
      env
      ''
    else "";

  in pkgs.writeShellScript name
    ''
      ${strictCmd}
      ${logCmd}
      ${debugCmd}
      ${printenvCmd}

      ${script}
    ''
```

If invoked, the expression writes such a script to the nix store.

```shell
nix-repl> writeLoggedScript = import ./writeLoggedScript.nix {}

nix-repl> :b writeLoggedScript "test.sh" "echo this is just a test" {}

this derivation produced the following outputs:
  out -> /nix/store/bzjllwyhy0zwm2f352a0gya8fp13qc7q-test.sh
```
