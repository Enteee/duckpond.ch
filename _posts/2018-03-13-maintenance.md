---
layout: post
categories: [meta]
keywords: [bootstrap, html list, dockerize, dehydrated, jekyll-responsive-images, jekyll-minifier, MathJax CDN]
---

I did some blog maintenance and released a new [duckpond.ch](/).

* Migrated to [Bootstrap v4.0](https://getbootstrap.com/).
* The list numbers overflowed. `list-style-position: outside;` is not a god fit for long roman numerals. I am now using [css counters](https://stackoverflow.com/questions/10428720/how-to-keep-indent-for-second-line-in-ordered-lists-via-css) and [liquid templating](https://github.com/Enteee/duckpond.ch/blob/master/index.html#L8) instead.
* [The twitter button now tweets 280 characters](https://github.com/Enteee/duckpond.ch/blob/master/_layouts/post.html#L12).
* [The logo is now responsive](https://github.com/Enteee/duckpond.ch/blob/master/static/css/main.css#L321).
* [Start nginx using dockerize](https://github.com/Enteee/duckpond.ch/blob/master/_env/nginx-dockerize/Dockerfile)
* [Request certificates using dehydrated](https://github.com/Enteee/duckpond.ch/blob/master/_env/dehydrated/Dockerfile)
* [jekyll watches now for changes and rebuilds automatically](https://github.com/Enteee/duckpond.ch/blob/master/docker-compose.yml)
* [jekyll-responsive-images](https://github.com/wildlyinaccurate/jekyll-responsive-image) with [this layout](https://github.com/Enteee/duckpond.ch/blob/master/_layouts/responsive_image.html) automatically creates responsive versions of images.
* [jekyll-minifier](https://github.com/digitalsparky/jekyll-minifier) minimizes `.html` and `.css` files.
* [MathJax CDN shutting down on 30. April 2017](https://www.mathjax.org/cdn-shutting-down/). Switched to Cloudflare.
* Removed annotations from the [duck in a toilet 404](/404.html).
