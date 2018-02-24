FROM wonderfall/isso

MAINTAINER Ente "ducksource@duckpond.ch"

ENV DOCKERIZE_VERSION v0.6.0
RUN set -ex \ 
  && apk add --no-cache openssl \
  && wget \
    "https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz" \
  && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz
