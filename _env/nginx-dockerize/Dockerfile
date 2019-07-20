ARG nginx_version=1.17.1
FROM nginx:${nginx_version}

MAINTAINER Ente "ducksource@duckpond.ch"

ARG dockerize_version=0.6.1
RUN set -ex \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
    ca-certificates \
    wget \
    inotify-tools \
  && wget \
    "https://github.com/jwilder/dockerize/releases/download/v${dockerize_version}/dockerize-linux-amd64-v${dockerize_version}.tar.gz" \
  && tar -C "/usr/local/bin" -xzvf "dockerize-linux-amd64-v${dockerize_version}.tar.gz" \
  && rm "dockerize-linux-amd64-v${dockerize_version}.tar.gz"

COPY start.sh .

ENTRYPOINT [ "dockerize" ]
CMD ["true"]
