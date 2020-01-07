---
layout: post
categories: [nix, bash]
title: reMarkable
keywords: [reMarkable, e ink, derivation, rMAPI]
---

I got my [reMarkable] recently and writing a few words about it will possibly
not hurt anyone. This is not a product review, I much rather try to focus on
technical aspects. Such as packaging the software and analyzing some of its
features.

{%
  responsive_image
  path: static/posts/reMarkable/remarkable.png
  caption: 'Sketching and writing on the device'
%}

# Table of Contents
{:.no_toc}

* entries
{:toc}

# Feature Overview

[reMarkable] is an electronic ink tablet designed for writing. E Ink writing
tablets promise excellent writing experience and a long battery lifetime. Which
should make them a good replacement for paper. There are a few competitors on
that market. For example the [Ratta SuperNote](https://goodereader.com/blog/product/supernote-a5-digital-note),
heavily featured on [goodereader][goodereader][^1].

My main use-cases for the tablet are to-do lists, meeting notes, mind maps,
user interface mock-ups and ugly sketches. I bought an e ink tablet because I was fed up with
manually digitalizing paper. I finally chose the [reMarkable] because all of the
developers [seem to be European cats](https://github.com/orgs/reMarkable/people)
and the ecosystem [is hackable to at least some degree](https://github.com/reHackable/awesome-reMarkable).
Also they [release frequently](https://support.remarkable.com/hc/en-us/sections/115001534689-Release-notes)
which is a big plus.

![reMarkable ecosystem](/static/posts/reMarkable/ecosystem.svg)
*IANAA - I am not an artist*

The device connects to the reMarkable cloud which has the main focus on document
sharing and backup. There is an App for Android / iOS as well as a client for
Windows and Mac OS. Sadly, the Linux client was discontinued in late 2017 [^2].
For cross operating system compatibility the device can serve its files using
a built in web server accessible via USB. When connected to the cloud, the device
has some optical character recognition (OCR) capabilities as well conversion of
documents to scalable vector graphics (SVG). The live view feature would be
amazing but also requires the native QT app on the receiving end.

# Software for the reMarkable and Some NixOS Derivations

In this section I am looking at software written for the [reMarkable] and because
NixOS is awesome I also tried to create some derivations.

## The Official Linux Client

Using the [NixOS packaging guideline for QT](https://nixos.org/nixpkgs/manual/#sec-language-qt),
and the following script:

```sh
#!/usr/bin/env bash
set -euo pipefail

binary="${1?Missing binary}"

while IFS= read -r lib
do
  if ldd "${binary}" | grep "not found" | grep -q "$lib";  then
    echo "=> ${lib}"
    nix-locate -1 -w "lib/${lib}"
    echo
  fi
done < <(patchelf --print-needed "${binary}")
```

I was able to quickly pin down all the dependencies and patch the distributed
executable with NixOS specific rpaths [^3]. With the resulting derivation [`remarkable-linux-client.nix`](/static/posts/reMarkable/remarkable-linux-client.nix) I can now run the
client inside a `nix-shell`:

```sh
$ nix-shell \
  --command reMarkable \
  -p $( \
    nix-build \
    --quiet \
    -E '(import <nixpkgs> {}).qt5.callPackage ./remarkable-linux-client.nix {}' \
  )
```

The application starts and connects to the cloud and all other features [^4]
work just fine. But I ran into big problems when displaying any of the drawings.
All notebooks are completely empty. Without success I have checked the whole log
for any hints which might indicate issues related to the packaging.

My best guess is that the [reMarkable] developers have changed the proprietary
file format and the extremely outdated Linux client is no longer able to read
that format properly. I got to this conclusion because the app logs the
following when displaying a a drawing:

```
Redrawing lines...
0 Lines starting at 0 of total 0
Redrawing lines completed in 0 ms
xochitl.documentworker: Storing page... 0
```

But this is just a guess. If you have a better idea what might be going wrong,
I am curious to hear about them in the comment section. Having spent quite a few
hours on this issue, I finally gave up getting the Linux client to work.
Therefore I started looking for open source alternatives:

## Accessing the reMarkable API With [rMAPI]

From the [README.md](https://github.com/juruen/rmapi/blob/master/README.md):

> [rMAPI] is a Go app that allows you to access the ReMarkable Cloud API programmatically.
>
> You can interact with the different API end-points through a shell. However, you can also run commands non-interactively. This may come in handy to script certain workflows such as taking automatic backups or uploading documents programmatically.
>
> ![rMAPI console](/static/posts/reMarkable/rmapi-console.gif)

In short a great tool! Creating a derivation and using it under NixOS was
easy. I opened a [pull request](https://github.com/juruen/rmapi/pull/78) to share
my work with the [rMAPI] project. Then I created another [pull request](https://github.com/NixOS/nixpkgs/pull/74657)
which adds this derivation to nixpkgs.

*Lessons Learned*: My initial Idea was to keep the full derivation in the [rMAPI]
repository and just use that repository in the nix-expression added to nixpkgs.
This approach did not work because it requires import from derivations (IFD),
which are currently disabled in hydra [^5].

With [rMAPI] I can now easily replicate the file sharing aspects of the native
Linux client. But how can we get the live view to work?

## Streaming the Framebuffer with [srvfb]

The idea is simple. We grab the framebuffer from the [reMarkable] and send it
back to the computer where we then render an image. In its most basic shape this
can be a [^6]:

```sh
$ ssh root@10.11.99.1 "cat /dev/fb0" | \
  ffmpeg -vcodec rawvideo \
         -f rawvideo \
         -pix_fmt gray16le \
         -s 1408,1872 \
         -i - \
         -vframes 1 \
         -f image2 \
         -vcodec mjpeg /tmp/frame.jpg
```

The amazing project [srvfb](https://github.com/Merovius/srvfb) took this idea
to the next level. From the [README.md](https://github.com/Merovius/srvfb/blob/master/README.md):

> This repository contains a small webserver that can serve the contents of a Linux framebuffer device as video over HTTP. The video is encoded as a series of PNGs, which are served in a multipart/x-mixed-replace stream. The primary use case is to stream a [reMarkable] screen to a computer and share it from there via video-conferencing or capturing it. For that reason, there is also a proxy-mode, which streams the frames as raw, uncompressed data from the remarkable and can then do the png-encoding on a more powerful machine. Whithout that, the framerate is one or two frames per second, which might not be acceptable (it might be, though).

Running this on the [reMarkable] is super easy. The result is great and even the
documented lag in non-proxy mode is acceptable. Problem solved.
Thank you [Merovius](https://github.com/Merovius), keep up the good work!

My last pain point with the reMarkable is the missing hardware button for flight
mode toggling. Because of battery lifetime I keep flight mode always on. But
when I do occasionally need internet, the flight mode option in the settings is
always a million clicks away.

# Hacking Hardware Button Flight Mode Toggling

I could not find a tool to get the flight mode working via button press, so I
built something on my own. But before doing so, I familiarized myself with the
internals of the device. For this I had to become `root` first.
Good news! It is possible and super easy:

1. Connect the tablet to your computer via USB.
2. Get the IP address as well as the root password from the about page.
3. `ssh`, done!

```sh
$ ssh root@10.11.99.1
ｒｅＭａｒｋａｂｌｅ
╺━┓┏━╸┏━┓┏━┓   ┏━╸┏━┓┏━┓╻ ╻╻╺┳╸┏━┓┏━┓
┏━┛┣╸ ┣┳┛┃ ┃   ┃╺┓┣┳┛┣━┫┃┏┛┃ ┃ ┣━┫┗━┓
┗━╸┗━╸╹┗╸┗━┛   ┗━┛╹┗╸╹ ╹┗┛ ╹ ╹ ╹ ╹┗━┛

remarkable: ~/ uname -a
Linux remarkable 4.9.84-zero-gravitas #1 Thu Jun 27 14:19:15 UTC 2019 armv7l GNU/Linux

remarkable: ~/ cat /proc/cpuinfo
processor         : 0
model name        : ARMv7 Processor rev 10 (v7l)
BogoMIPS          : 24.00
Features          : half thumb fastmult vfp edsp neon vfpv3 tls vfpd32
CPU implementer   : 0x41
CPU architecture  : 7
CPU variant       : 0x2
CPU part          : 0xc09
CPU revision      : 10

Hardware          : Freescale i.MX6 SoloLite (Device Tree)
Revision          : 0000
Serial            : 1f2e89d4ee67f7f0
```

The remarkable File system structure is partially documented on the [remarkable wiki](https://remarkablewiki.com/tech/filesystem).
Some other locations I found interesting:

* `/home/root/.local/share/remarkable/xochitl/`: Your documents and metadata.
* `/etc/remarkable.conf`: Passwords and keys.
```sh
remarkable: ~/ grep -r Password /etc/remarkable.conf
DeveloperPassword=*** ROOT PASSWORD (masked) ***
Password=*** Screen lock password (masked) ***
```
```sh
remarkable: ~/ sed -n '/wifinetworks/,$p' /etc/remarkable.conf
[wifinetworks]
SSID1=@Variant(*** Key for Wifi network (masked) ***)
SSID2=@Variant(*** Key for Wifi network (masked) ***)
```

Enough of the playtime, let's get cracking. Again, my goal is to toggle flight mode
when the left and right button are both pressed at the same time. For this I
have to listen on evdev events and once both buttons are pressed run
`rfkill block all` to enable flight mode or `rfkill unblock all` to disable it again.

In my simple approach I am using [evtest] to parse the binary events from
`/dev/input/event*`. First I cross compiled [evtest] with [dockercross] for the
32 bit ARMV7-A and copied the resulting binary to the reMarkable.

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

evdev exposes three different event sources on the [reMarkable]:

{:.table}
| Device | Name | Description |
| ------ | ---- | ----------- |
| `/dev/input/event0` | Wacom I2C Digitizer | The capcitive pen input device |
| `/dev/input/event1` | cyttsp5_mt | The touchscreen |
| `/dev/input/event2` | gpio-keys | The hardware buttons |

The following `bash` script uses the just compiled [evtest] binary to fetch and
handle button press events on `/dev/input/event2`. With
`rfkill list | grep -q "Soft blocked: no"` it then detects if flight mode is
disabled and calls out to `rfkill` accordingly.

```sh
#!/usr/bin/env bash
set -euo pipefail

DEVICE='/dev/input/event2'
EVTEST=$(command -v evtest || echo './evtest')
RFKILL=$(command -v rfkill)

LEFT_DOWN=false
RIGHT_DOWN=false

toggle_flight_mode(){
  if "$RFKILL" list | grep -q "Soft blocked: no"; then
    "$RFKILL" block all
  else
    "$RFKILL" unblock all
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


  "$EVTEST" "$DEVICE" | while read -r line; do
      case $line in
          ($key_left_down) LEFT_DOWN=true ;;
          ($key_left_up) LEFT_DOWN=false ;;
          ($key_right_down) RIGHT_DOWN=true ;;
          ($key_right_up) RIGHT_DOWN=false ;;
          (*) continue ;;
      esac
      echo "$line -> LEFT ${LEFT_DOWN} , RIGHT: ${RIGHT_DOWN}"

      if [ "${LEFT_DOWN}" = true ] && [ "${RIGHT_DOWN}" = true ]; then
        toggle_flight_mode
      fi
  done
}

handle_events
```

done!.. One downside coming from directly using `rfkill`, is that the user interface
does not properly detect this state change. Which means we can get the reMarkable into
weird states where the device is connected to a network with the flight mode icon
on. Rebooting the device recovers the clean state again. [But let us call this a
feature, shall we?](https://www.youtube.com/watch?v=JYAq-7sOzXQ)

# Conclusion

I have been using the reMarkable for a few weeks now and I am very satisfied
with the product. The overall user experience is very good. And the graphite tips
don't wear out too fast. For the future I would like to see the following features
implemented:

* toggle flight mode with a hardware switch
* mixed PDF and sheet notebooks
* basic shapes such as circles, squares and lines

Maybe we get all this with the reMarkable2. It seems that a new device is on its
way. [reMarkable] has filed a [request for certification by the FCC (FCC ID 2AMK2-RM110)](https://fccid.io/2AMK2-RM110) which contains a wealth of pictures and specs. But in a letter correspondence
from the 22. November 2019 they requested the dismissal of that FCC ID.
Whatever that means...

Wrapping up, the [reMarkable] is a perfect example how open devices can encourage
a community to make so much more out of a already great product. I sincerely hope
that the company stays as open as it is right now [^7] and no money hungry manager
or acquiring company destroys what they built so far.

[^1]: The platform is so unnaturally biased towards that alternative, leading me into questioning their independence. We all need money to support our life. But a bit more transparency, especially when your main focus are product reviews, would be nice.
[^2]: This needs to change!
[^3]: 20.03pre199897.471869c9185
[^4]: Except the most important one...
[^5]: I also recommend reading [this excellent article by Domen Kožar](https://blog.hercules-ci.com/2019/08/30/native-support-for-import-for-derivation/)
[^6]: Shamelessly stolen from [canselcik/libremarkable Wiki](https://github.com/canselcik/libremarkable/wiki/Framebuffer-Overview)
[^7]: I can haz `xochitl` github repo?

[reMarkable]:https://remarkable.com/
[goodereader]:https://goodereader.com/blog/product/supernote-a6-digital-note
[rMAPI]:https://github.com/juruen/rmapi
[srvfb]:https://github.com/Merovius/srvfb
[evtest]:https://github.com/freedesktop-unofficial-mirror/evtest
[dockercross]:https://github.com/dockcross/dockcross
