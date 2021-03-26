ARG docker_version=19.03

# https://github.com/docker/cli/issues/2281
# create an "alias" because COPY --from does not support expanding variables
FROM docker:${docker_version} AS docker
FROM debian-dockerize

MAINTAINER Ente "ducksource@duckpond.ch"

COPY --from=docker /usr/local/bin/docker /usr/local/bin/

ARG borgbackup_version="1.1.9-2+deb10u1"
RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      borgbackup="${borgbackup_version}"

# Make service writable directories
ARG borgbackup_repo="/rw/backup/repo"
ARG borgbackup_volumes="/rw/backup/volumes"
RUN set -ex \
  && SERVICE_WRITABLE_DIRS=( \
    "${borgbackup_repo}" \
    "${borgbackup_volumes}" \
  ) \
  && mkdir -p "${SERVICE_WRITABLE_DIRS[@]}" \
  && chown -R \
    "${SERVICE_USER}":"${SERVICE_GROUP}" \
    "${SERVICE_WRITABLE_DIRS[@]}"

#USER "${SERVICE_UID}":"${SERVICE_USER}"

COPY lib.sh .
COPY backup.sh .
COPY restore.sh .
COPY start.sh .
CMD ["./start.sh"]
