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
that market. For example the [Ratta SuperNote](https://goodereader.com/blog/product/supernote-a5-digital-note), heavily featured on [goodereader][goodereader][^1].

My main use-cases for the tablet are to-do lists, meeting notes, mind maps,
ui mock-ups and ugly sketches. I bought an e ink tablet because I was fed up with
manually digitalizing paper. I finally chose the [reMarkable] because all the
developers [seem to be european cats](https://github.com/orgs/reMarkable/people)
and the ecosystem [is hackable to at least some degree](https://github.com/reHackable/awesome-reMarkable). Also they seem to [release frequently](https://support.remarkable.com/hc/en-us/sections/115001534689-Release-notes).

![reMarkable ecosystem](/static/posts/reMarkable/ecosystem.svg)
*You must forgive me my drawing skills*

The device connects to the reMarkable cloud which has the main focus on document
sharing and backup. There is an App for Android / iOS as well as a client for
Windows and Mac OS. Sadly, the Linux client was discontinued in late 2017 [^2].
For cross operating system compatibility the device can serve its files using
a built in web server, accessible via USB. When connected to the cloud, the device
has some optical character recognition (OCR) capabilities as well conversion of
documents to scalable vector graphics (SVG). The live view feature would be
amazing but also requires the native QT app on the receiving end.

# NixOS derivations

## Linux Client

Using the [NixOS packaging guideline for QT](https://nixos.org/nixpkgs/manual/#sec-language-qt),
and the following script:

```shell
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
executable with rpaths needed to run the executable under NixOS [^3].
Using the following derivation:

```nix
{
  mkDerivation,
  fetchurl, dpkg,
  glibc, stdenv,

  qtbase, qtdeclarative, qtsvg, qtwebsockets,
  qtquickcontrols, qtquickcontrols2, qtgraphicaleffects,

  libsForQt511,
  libGLU_combined,
}:

let

in mkDerivation rec {

  name = "reMarkable-client";

  src = fetchurl {
    url = https://remarkable.engineering/remarkable-linux-client-0.0.5-16-1408-g7eca2b66.tgz;
    sha256 = "sha256:1305scjyi4b1wh4vr8ccszz11dvgwyka9hivyzv5j8ynqsnij58s";
  };

  buildInputs = [
    stdenv.cc.cc.lib

    libGLU_combined
    libsForQt511.karchive

    qtbase

    qtdeclarative
    qtsvg
    qtbase
    qtwebsockets

    qtquickcontrols
    qtquickcontrols2
    qtgraphicaleffects

  ];


  installPhase = ''
    mkdir -p $out/{bin,lib}
    cp reMarkable $out/bin
    cp libpdfium.so.1 $out/lib

    patchelf --set-interpreter \
      "${glibc}/lib/ld-linux-x86-64.so.2" \
      "$out/bin/reMarkable"


    patchelf \
      --set-rpath \
      "$out/lib:${libsForQt511.karchive}/lib:${qtdeclarative}/lib:${qtsvg}/lib:${qtbase.out}/lib:${qtwebsockets}/lib:${libGLU_combined}/lib:${stdenv.cc.cc.lib}/lib" \
      "$out/bin/reMarkable"
  '';
}
```

saved to a file called `remarkable-linux-client.nix`, I can now run the client
using `nix-shell`:

```shell
$ nix-shell \
  --command reMarkable \
  -p $( \
    nix-build \
    --quiet \
    -E '(import <nixpkgs> {}).qt5.callPackage ./remarkable-linux-client.nix {}' \
  )
```

The application starts and connects to the cloud just fine. But I ran into
problems when displaying any of the drawings. If I do open a notebook, nothing
is shown. I have checked the whole log for any hints which might indicate issues
related to the packaging. But I could not find any. Also, all other features [^4]
work just fine.

My best guess would be that the [reMarkable] developers have changed the proprietary
file format and the extremely outdated Linux client is no longer able to read
that format properly. I reached to this conclusion because the app logs the
following when displaying a a drawing:

```
Redrawing lines...
0 Lines starting at 0 of total 0
Redrawing lines completed in 0 ms
xochitl.documentworker: Storing page... 0
```

But this is just a guess. If you have a better idea about what might be going
wrong, I am curious to hear about them in the comment section. Having spent
quite a few hours on this issue I finally gave up getting the Linux client to
work.

## [rMAPI]

From the [README.md](https://github.com/juruen/rmapi/blob/master/README.md):

> [rMAPI] is a Go app that allows you to access the ReMarkable Cloud API programmatically.
>
> You can interact with the different API end-points through a shell. However, you can also run commands non-interactively. This may come in handy to script certain workflows such as taking automatic backups or uploading documents programmatically.
>
> ![rMAPI console](/static/posts/reMarkable/rmapi-console.gif)

In short, a great tool! Creating a derivation and using it under NixOS was
easy. I opened a [pull request](https://github.com/juruen/rmapi/pull/78) in
order to share my work with the [rMAPI] project. Then I did also create another
[pull request](https://github.com/NixOS/nixpkgs/pull/74657) which adds this
derivation to nixpkgs. My initial Idea was to keep all relavant `*.nix` files
in the [rMAPI] repository and just use that repository in the nix-expression
added to nixpkgs. This approach did not work because it requires import
from derivations (IFD), which are currently disabled in hydra [^5].

With [rMAPI] we can eaisly replicate the file sharing aspects of the natvie
Linux client. But how can we get the live view to work?

## [srvfb]

From the [README.md](https://github.com/Merovius/srvfb/blob/master/README.md):

> This repository contains a small webserver that can serve the contents of a linux framebuffer device as video over HTTP. The video is encoded as a series of PNGs, which are served in a multipart/x-mixed-replace stream. The primary use case is to stream a [reMarkable] screen to a computer and share it from there via video-conferencing or capturing it. For that reason, there is also a proxy-mode, which streams the frames as raw, uncompressed data from the remarkable and can then do the png-encoding on a more powerful machine. Whithout that, the framerate is one or two frames per second, which might not be acceptable (it might be, though).

Problem solved! Well, almost. I would still like to be able to toggle flight mode
by a button press.

# Hacking the reMarkable

Since I could not find a tool to get the flightmode working via button press, I
had to build something on my own. But before doing so, I had to familiarize myself
with the intestines of the device itself. For this I had to become `root` on the device.

## SSH to the device

It is possible and super easy:

1. Connect the tablet to your computer via USB.
2. Get the ip address as well as the root password from the about page.
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

The remarkable Filesystem structure is partially documented on the [remarkable wiki](https://remarkablewiki.com/tech/filesystem). Some other locations I found particularly intersting:

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
Duckpond.ch=@Variant(*** Key for Wifi network (masked) ***)
Tomato50=@Variant(*** Key for Wifi network (masked) ***)
```

## Toggle Flight Mode

# The new reMarkable2

It seems that a new device is on its way. But just not quite there. reMarkable
has filed a [request for certification by the FCC](https://fccid.io/2AMK2-RM110),
which contains a wealth of pictures and specs for the new device. But in a letter
correspondence from the 22. November 2019 they also requested the dismissal of
that FCC ID. Whatever that means...

# Conclusion

I have been using the reMarkable for a few weeks now and I am very satisfied
with the product. The overall user experience is very good. And the graphite tips
don't wear out too fast. For the future I would like to see the following features
implemented:

* toggle flight mode with a hardware switch
* mixed PDF and sheet notebooks
* basic shapes such as circles, squares and lines

The reMarkable is a perfect example how open devices can encurage a community to
make so much more out of a already great product. I sincerely hope that the
reMarkable stays as open as it is right now [^6] and no money hungry manager or
acquiring company destroys what they built so far.


[^1]: The platform is so unnaturally biased towards that alternative, leading me into questioning their independence. We all need money to support our life. But a bit more transparency, especially when your main focus are product reviews, would be nice.
[^2]: This needs to change!
[^3]: 20.03pre199897.471869c9185
[^4]: Except the most important one...
[^5]: I also recommend reading [this excellent article by Domen Kožar](https://blog.hercules-ci.com/2019/08/30/native-support-for-import-for-derivation/)
[^6]: I can haz `xochitl` github repo?

[reMarkable]:https://remarkable.com/
[goodereader]:https://goodereader.com/blog/product/supernote-a6-digital-note
[rMAPI]:https://github.com/juruen/rmapi
[srvfb]:https://github.com/Merovius/srvfb
