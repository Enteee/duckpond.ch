---
layout: post
categories: [astronomy]
keywords: [moon]
---

After a star tracking project I got hooked on astronomy. This post wraps up my first attempt photographing the moon.

# The Rig

Astrophotography can get extremely expensive. Since I'm a rookie I tried to keep everything affordable. My 300$ rig:

* [Second hand Celestron AstroMaster 130EQ telescope](https://www.celestron.com/products/astromaster-130eq-telescope)
* [AstroMaster/PowerSeeker motor driver](https://www.celestron.com/products/astromaster-powerseeker-motor-drive)
* [Raspberry Pi 3 Model B](https://www.raspberrypi.org/products/raspberry-pi-3-model-b/)
* [Camera Module V2](https://www.raspberrypi.org/products/camera-module-v2/)
* [Power Bank 14500 mAh](https://www.headdaddy.com/index.php/home/product/A0094622/)
* [Raspberry Pi 3 case](https://www.raspberrypi.org/products/raspberry-pi-3-case/)
* [Wrigley's Extra spearmint chewing gum](https://groceries.morrisons.com/webshop/product/Wrigleys-Extra-Spearmint-Chewing-Gum/217842011)
* [Duct tape](https://en.wikipedia.org/wiki/Duct_tape)

{%
  responsive_image 
  path: static/posts/first-steps-on-the-moon/astro-pi.jpg
  caption: "The Raspberry Pi 3 connected to the camera"
%}

{%
  responsive_image 
  path: static/posts/first-steps-on-the-moon/extra-picam.jpg 
  caption: "An 'extra' universal T-Adapter"
%}

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/rig-outside.jpg
  caption: "The rig assembled and ready"
%}

# First Image

31\. January 2018, the Blue Moon and a clear sky made a perfect opportunity for a first test. After I pointed the equatorial mount towards the celestial north pole and adjusted the motor speed the rig was ready.

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/blue-moon.jpg
  caption: "A Blue Moon has nothing to do with the color"
%}

After a bit of fiddling with [raspistill] parameters, I decided that I'd set the shutter speed to 10 seconds and leave everything else untouched. This is definitely not a smart thing to do, fine-tuning recording parameters is important. Automatic adjustment will ruin the recording series! But for this first project the goal was to accumulate know-how for the whole process rather than each individual step. I definitely have to revisit and improve.

```bash
$ raspistill \
    --stats \
    --mode 3 \
    --encoding bmp \
    --quality 100 \
    --timestamp \
    --output 'moon%d.bmp' \
    --shutter 10000 \
    --timeout 0 \
    --nopreview
```

I decided to use the BMP encoding because I though a simple bitmap is the closes I can get to a RAW image. This assumption is false. [The BMP file format is is much more complex than I assumed](https://en.wikipedia.org/wiki/BMP_file_format)[^BMP-JPEG]. Next time i will try extracting the RAW data from the JPEG as described [in the awesome Picamera documentation](http://picamera.readthedocs.io/en/release-1.13/recipes2.html?highlight=bayer#raw-bayer-data-captures). Between `2018-01-31T22:07:53+00:00` and `2018-02-01T00:07:37+00:00` I finally did the recording.

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/moon1517436473.bmp
  caption: "moon1517436473.bmp: The first image recorded"
%}

Looks a bit red and blurry to me. I tried to get around this by post-processing the images.

# Post-processing

First I manually filtered distorted, broken and extremely blurry images, leaving me with 139 images worth 3.2 GiB of data. Then using [hugin] with mostly default settings and a field of view set to 20° I combined them to the image below.

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/hugin.png
  caption: "Assembling the final image in hugin"
%}

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/panorama-unprocessed.png
  caption: "The unprocessed image"
%}

The image is still a bit to red and blurry. This is why I applied the following transformations in [gimp]:
1. Desaturate
  * Average strategy
2. Adjust brightness and contrast
  * Brightness: -60
  * Contrast: 60
3. Despeckle
  * Adaptive
  * Recursive
  * Black level: -1
  * White level: 256
4. Sharpen
  * Sharpness: 50

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/panorama-processed.png
  caption: "The processed image"
%}

# Final thoughts

Compared to the imagery [on wikimedia](https://upload.wikimedia.org/wikipedia/commons/e/e1/FullMoon2010.jpg) mine is a child's drawing. But hey, it's mine. And I identified a lot of things I want to improve and test:

* Write a program which allows for finding dynamically best recording parameters
* Come up with a procedure to calibrate the motor speed precisely
* RAW images instead of BMP
* Try overlaying multiple images to reduce noise
* Try [Dark-frame substraction](https://en.wikipedia.org/wiki/Dark-frame_subtraction)


[^startracking]:Apparently 23 hours 54 minutes 58 seconds 23 hours 56 minutes 4 seconds
[^BMP-JPEG]:And can even hold an entire JPEG! Why?

[raspistill]:https://github.com/raspberrypi/documentation/blob/master/usage/camera/raspicam/raspistill.md
[hugin]:http://hugin.sourceforge.net/
[gimp]:https://www.gimp.org/
