---
layout: post
categories: [bash]
keywords: [chromecast, ffmpeg]
---

Chromecast does only support a selection of audio and video codecs. I have used
the following a lot to convert almost any video for streaming on the Chromecast:

```sh
$ ffmpeg \
  -i input.mp4
  -map 0:v:0 \
  -c:v copy \
  -map 0:a:0 \
  -map 0:a:0 \
  -c:a:0 aac \
  -ac:a:0 2 \
  -b:a:0 192k \
  -c:a:1 copy \
  output.mp4
```

This post is mostly just a copy&paste from [stix.id.au](https://www.stix.id.au/wiki/ffmpeg_conversion_for_Chromecast).
Just reposting this here to preserve the information. All credits to the original author.
