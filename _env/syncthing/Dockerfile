FROM debian-dockerize

# Install syncthing
ARG syncthing_version="1.14.0"
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
      apt-get install --no-install-recommends --no-install-suggests -y \
        syncthing="${syncthing_version}"

# Make service writable directories
RUN set -ex \
  && SERVICE_WRITABLE_DIRS=( \
    "/rw/syncthing" \
    "/service/volume-backup" \
    "/service/backup" \
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
