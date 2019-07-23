ARG openvpnas_version=2.7.4-ls28
FROM linuxserver/openvpn-as:${openvpnas_version}

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


# Add local files
COPY /root /

# make db directory so that we can copy
# some configuration files to it before
# the application starts
RUN set -ex \
  && mkdir -p /config/etc/db/

ENTRYPOINT [ "dockerize" ]
CMD ["true"]
