---
layout: post
title:  "Docker hell"
date:   2016-05-27
categories: [meta]
---

First things first, I love [doker]!
But there are some pitfalls when building [docker] images. And I probably hit them all when building the docker setup for duckpond.ch.

As you might have noticed, https & isso is working now.

# Volumnes are not mounted during build.
# Ports are not 
# Relative paths to nginx (not in docker-compose)
# debian (veryyyy old) rusty , dont' trust github

# entry point bug

[docker]:https://www.docker.com/
[letsencrypt.sh]:https://github.com/lukas2511/letsencrypt.sh

