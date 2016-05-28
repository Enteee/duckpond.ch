---
layout: post
keywords: [docker, debian, letsencrypt]
categories: [meta]
---

First things first: I love [docker]!

But there are some pitfalls when building containers with [docker-compose]:

* Volumes are not mounted and ports not bound during build: This is obvious when you look at ```man docker build```, but not when you're working with docker-compose.yml. Thus, don't try to run a service during build, looking at you [letsencrypt]. Btw; [letsencrypt.sh] is a good alternative to the fat [letsencrypt] standard client.
* Make sure that you know your pwd:
  * Paths in docker-compose.yml and Dockerfile are relative to the folder containing the said file.
  * Once you're in a container your working directory is /.
* Not docker related: Do not assume that software in a debian-package works as described in the project wiki. Granny Debby[^1] is old and rusty! Use ```$ docker exec -ti container_hash bash``` and check what's relly supported.
* [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint) and [CMD](https://docs.docker.com/engine/reference/builder/#cmd) are not that easy to deal with [^2]. Note that:

  > Command line arguments to docker run <image> will be appended after all elements in an exec form ENTRYPOINT, and will <b>override</b> all elements specified using CMD

* Use the follwing two commands frequently if you don't want to run out of disk space:

  ```
  $ docker rm $(docker ps -a -q)
  ```

  ```
  $ docker rmi -f $(docker images | grep "<none>" | awk "{print \$3}")
  ```
* Use [networking]. No pitfal here, JUST DO IT!

[^1]:Don't google that!
[^2]:[https://github.com/docker/docker/issues/5147](https://github.com/docker/docker/issues/5147)

[docker]:https://www.docker.com/
[docker-compose]:https://docs.docker.com/compose/
[networking]:https://docs.docker.com/compose/networking/
[letsencrypt]:https://letsencrypt.org/
[letsencrypt.sh]:https://github.com/lukas2511/letsencrypt.sh
