FROM debian-dockerize

# Install bind
ARG bind_version=1:9.11.5.P4+dfsg-5.1+deb10u3
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
      apt-get install --no-install-recommends --no-install-suggests -y \
        bind9

COPY --chown=root:bind named.conf.options /etc/bind/named.conf.options
COPY --chown=root:bind named.conf.local /etc/bind/named.conf.local
COPY --chown=root:bind zones /etc/bind/zones/

# Move ownership of files belogining to bind to service accoutn
RUN set -ex \
  && find / \
    -path /sys -prune -o -path /proc -prune -o \
    -type d,f,l \
    -user bind \
    -exec chown "${SERVICE_USER}" "{}" \; \
  && find / \
    -path /sys -prune -o -path /proc -prune -o \
    -type d,f,l \
    -user bind \
    -exec chown ":${SERVICE_GROUP}" "{}" \; \
  && userdel \
    --force \
    --remove \
    bind

# Make service writable directories
RUN set -ex \
  && SERVICE_WRITABLE_DIRS=( \
    "/rw/" \
    "/run/named" \
  ) \
  && mkdir -p "${SERVICE_WRITABLE_DIRS[@]}" \
  && chown -R \
    "${SERVICE_USER}":"${SERVICE_GROUP}" \
    "${SERVICE_WRITABLE_DIRS[@]}"


USER "${SERVICE_UID}":"${SERVICE_USER}"

EXPOSE 53

COPY start.sh .
CMD ["./start.sh"]
