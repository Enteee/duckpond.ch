FROM debian-dockerize

# Install isso
ARG isso_version=0.12.5
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
      apt-get install --no-install-recommends --no-install-suggests -y \
        pipx \
        python3-dev \
        sqlite3 \
        build-essential \
        python3-gevent \
        libffi-dev \
    && pipx install \
        "isso==${isso_version}"

# Make service writable directories
RUN set -ex \
  && SERVICE_WRITABLE_DIRS=( \
    "/rw/db" \
  ) \
  && mkdir -p "${SERVICE_WRITABLE_DIRS[@]}" \
  && chown -R \
    "${SERVICE_USER}":"${SERVICE_GROUP}" \
    "${SERVICE_WRITABLE_DIRS[@]}"

USER "${SERVICE_UID}":"${SERVICE_USER}"

EXPOSE 8080

COPY start.sh .
CMD ["./start.sh"]
