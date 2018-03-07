FROM nginx

MAINTAINER Ente "ducksource@duckpond.ch"

ENV DOCKERIZE_VERSION v0.6.0
RUN set -ex \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
    ca-certificates \
    wget \
    inotify-tools \
  && wget \
    https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY start.sh .

ENTRYPOINT [ "dockerize" ]
CMD ["true"]
