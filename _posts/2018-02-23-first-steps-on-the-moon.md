---
layout: post
categories: [astronomy]
keywords: [moon]
---

After a star tracking project I got hooked on astronomy. This post wraps up my first attempt photographing the Moon.

# The Rig

Astrophotography can get extremely expensive. I'm a rookie therefore I tried to keep everything affordable. My 300$ rig:

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
  caption: 'The Raspberry Pi 3 connected to the camera'
%}

{%
  responsive_image 
  path: static/posts/first-steps-on-the-moon/extra-picam.jpg 
  caption: 'An "extra" universal T-Adapter'
%}

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/rig-outside.jpg
  caption: 'The rig assembled and ready'
%}

# First Image

31\. January 2018, the Blue Moon and a clear sky made a perfect opportunity for a first test. I pointed the equatorial mount towards the celestial north pole and adjusted the motor to account for the Earth's rotation. After I attached the "extra" universal T-Adapter the telescope was ready. Then I adjusted the focal point using [`raspistill`][raspistill]'s preview over Wi-Fi [^WiFi].

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/blue-moon.jpg
  caption: 'A Blue Moon has nothing to do with the color'
%}

After a bit of fiddling with the parameters I decided to set shutter speed to 10 seconds and leave everything else untouched. This was definitely not a smart move. Fine-tuning recording parameters is important. Moreover, automatic tuning of parameters will ruin your long running recording series! But for this first project the goal was to accumulate know-how. The perfect shot is out of my reach, yet.

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

I choose to use BMP encoding for the images. Simply because I thought a bitmap is the closest I can get to a RAW image. This assumption is false. [The BMP file format is is much more complex than I assumed](https://en.wikipedia.org/wiki/BMP_file_format)[^BMP-JPEG]. Next time i will try extracting the RAW data from the JPEG as described [in the awesome Picamera documentation](http://picamera.readthedocs.io/en/release-1.13/recipes2.html?highlight=bayer#raw-bayer-data-captures). Between `2018-01-31T22:07:53+00:00` and `2018-02-01T00:07:37+00:00` I then finally started recording.

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/moon1517436473.bmp
  caption: 'moon1517436473.bmp: The first image'
%}

Well, the images are generally too red and blurry. I tried to correct this during post-processing.

# Post-processing

First I manually removed distorted and extremely blurry images. Leaving me with 139, worth 3.2 GiB of data. [hugin][hugin] [^hugin_awesome][^hugin_awesome2] then assembled the panorama below. Again, everything on default parameters with a 20° field of view.

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/hugin.png
  caption: 'Assembling the Moon in hugin'
%}

{%
  responsive_image
  path: static/posts/first-steps-on-the-moon/panorama-unprocessed.png
  caption: 'The unprocessed panorama'
%}

The result is still red and blurry. This is why I then applied the following transformations in [gimp]:

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
  caption: 'The processed image'
%}

# Final thoughts

Compared to the imagery [on wikimedia](https://upload.wikimedia.org/wikipedia/commons/e/e1/FullMoon2010.jpg) mine is a child's drawing. But it's mine! I am happy with the result. Not necessarily for the image per se. Mostly because I was able to identify a lot of things to improve and test:

* Write a program which finds automatically the best recording parameters
* Come up with a procedure to calibrate the motor
* RAW instead of BMP
* Try overlaying multiple images to reduce noise
* Try [Dark-frame substraction](https://en.wikipedia.org/wiki/Dark-frame_subtraction)


[^WiFi]:The future is now!
[^BMP-JPEG]:And can even hold an entire JPEG! Why?
[^hugin_awesome]:Awesome software, check it out now.
[^hugin_awesome2]:Why are you still here? Off you go!

[raspistill]:https://github.com/raspberrypi/documentation/blob/master/usage/camera/raspicam/raspistill.md
[hugin]:http://hugin.sourceforge.net/
[gimp]:https://www.gimp.org/
