FROM debian-dockerize

MAINTAINER Ente "ducksource@duckpond.ch"

# Install syncthing
ARG syncthing_version="1.0.0~ds1-1+b11"
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
      apt-get install --no-install-recommends --no-install-suggests -y \
        syncthing="${syncthing_version}"

# Make service writable directories
RUN set -ex \
  && SERVICE_WRITABLE_DIRS=( \
    "/rw/Sync/letsencrypt" \
    "/rw/Sync/isso" \
    "/rw/Sync/cryptpad" \
  ) \
  && mkdir -p "${SERVICE_WRITABLE_DIRS[@]}" \
  && chown -R \
    "${SERVICE_USER}":"${SERVICE_GROUP}" \
    "${SERVICE_WRITABLE_DIRS[@]}"

USER "${SERVICE_UID}":"${SERVICE_USER}"

EXPOSE 22000
EXPOSE 21027
EXPOSE 8384

COPY start.sh .
CMD ["./start.sh"]
