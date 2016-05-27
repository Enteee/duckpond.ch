FROM debian:jessie 

MAINTAINER Ente "ducksource@duckpond.ch"

RUN echo "deb http://ftp.ch.debian.org/debian/ jessie-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        ca-certificates \
        letsencrypt.sh

CMD [ "letsencrypt.sh", "-c" ]
