ARG docker_version=19.03

# https://github.com/docker/cli/issues/2281
# create an "alias" because COPY --from does not support expanding variables
FROM docker:${docker_version} AS docker
FROM debian-dockerize

MAINTAINER Ente "ducksource@duckpond.ch"

COPY --from=docker /usr/local/bin/docker /usr/local/bin/

RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      dehydrated

# Make service writable directories
RUN set -ex \
  && SERVICE_WRITABLE_DIRS=( \
    "/rw/certs" \
    "/rw/certs_mailcow" \
    "/rw/acme-challenge" \
    "/rw/accounts" \
    "/rw/chains" \
  ) \
  && mkdir -p "${SERVICE_WRITABLE_DIRS[@]}" \
  && chown -R \
    "${SERVICE_USER}":"${SERVICE_GROUP}" \
    "${SERVICE_WRITABLE_DIRS[@]}"

USER "${SERVICE_UID}":"${SERVICE_USER}"

COPY start.sh .
CMD ["./start.sh"]
