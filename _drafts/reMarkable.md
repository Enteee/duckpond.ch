---
layout: post
categories: [nix, bash]
title: reMarkable
keywords: []
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

[reMarkable] is an electronic ink tablet designed for writing. E Ink writing
tablets promise excellent writing experience and a long battery lifetime. Which
should make them a good replacement for paper. There are a few competitors on
that market. For example the [Ratta SuperNote](https://goodereader.com/blog/product/supernote-a5-digital-note), heavily featured on [goodereader][goodereader][^1].

My main use-cases for the tablet are to-do lists, meeting notes, mind maps,
ui mock-ups and ugly sketches. I bought an e ink tablet because I was fed up with
manually digitalizing paper. I finally chose the [reMarkable] because all the
developers [seem to be european cats](https://github.com/orgs/reMarkable/people)
and the ecosystem [is hackable to at least some degree](https://github.com/reHackable/awesome-reMarkable).

# Features

![reMarkable ecosystem](/static/posts/reMarkable/ecosystem.svg)

The device connects to the reMarkable cloud which has the main focus on document
sharing and backup. There is an App for Android / iOS as well as a client for
Windows and Mac OS. Sadly, the Linux client was discontinued in late 2017 [^2].
For cross operating system compatibility the device can serve its files using
a built in web server, accessible via USB. When connected to the cloud, the device
has some optical character recognition (OCR) capabilities as well conversion of
documents to scalable vector graphics (SVG). The live view feature would be
amazing but also requires the native QT app on the receiving end.

# Reviving the Linux Client

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

# [rMAPI]

From the [README.md](https://github.com/juruen/rmapi/blob/master/README.md):

> [rMAPI] is a Go app that allows you to access the ReMarkable Cloud API programmatically.
> 
> You can interact with the different API end-points through a shell. However, you can also run commands non-interactively. This may come in handy to script certain workflows such as taking automatic backups or uploading documents programmatically.
> 
> ![rMAPI console](/static/posts/reMarkable/rmapi-console.gif)

In short, a great tool! Creating a derivation and using it under NixOS was
easy. I opened a [pull request](https://github.com/juruen/rmapi/pull/78) in
order to share my efforts with them. Depending on the community feedback I might
go ahead an add a derivation for [rMAPI] to nixpkgs later.

# Conclusion

I have been using the reMarkable for a few weeks now and I am very satisfied
with the product. The overall user experience is very good. And the graphite tips
don't wear out too fast. For the future I would like to see the following features
implemented:

* toggle flight mode with a hardware switch
* mixed PDF and sheet notebooks
* basic shapes such as circles, squares and lines


[^1]: The platform is so unnaturally biased towards that alternative, leading me into questioning their independence. We all need money to support our life. But a bit more transparency, especially when your main focus are product reviews, would be nice.
[^2]: This needs to change!
[^3]: 20.03pre199897.471869c9185
[^4]: Except the most important one...

[reMarkable]:https://remarkable.com/
[goodereader]:https://goodereader.com/blog/product/supernote-a6-digital-note
[rMAPI]:https://github.com/juruen/rmapi
