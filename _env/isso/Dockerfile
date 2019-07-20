FROM wonderfall/isso:latest

MAINTAINER Ente "ducksource@duckpond.ch"

ARG dockerize_version=0.6.1
RUN set -ex \
  && apk add --no-cache openssl \
  && wget \
    "https://github.com/jwilder/dockerize/releases/download/v${dockerize_version}/dockerize-linux-amd64-v${dockerize_version}.tar.gz" \
  && tar -C "/usr/local/bin" -xzvf "dockerize-linux-amd64-v${dockerize_version}.tar.gz" \
  && rm "dockerize-linux-amd64-v${dockerize_version}.tar.gz"

ENTRYPOINT ["dockerize"]
