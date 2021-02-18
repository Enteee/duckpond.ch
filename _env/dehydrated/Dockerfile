ARG debian_version=10.0
ARG docker_version=19.03

# https://github.com/docker/cli/issues/2281
# create an "alias" because COPY --from does not support expanding variables
FROM docker:${docker_version} AS docker

FROM debian:${debian_version}

MAINTAINER Ente "ducksource@duckpond.ch"

COPY --from=docker /usr/local/bin/docker /usr/local/bin/

RUN set -ex \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        ca-certificates \
        dehydrated
