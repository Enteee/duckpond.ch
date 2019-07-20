ARG debian_version=10.0
FROM debian:${debian_version}

MAINTAINER Ente "ducksource@duckpond.ch"

RUN set -ex \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        ca-certificates \
        dehydrated
