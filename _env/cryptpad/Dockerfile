FROM debian-dockerize AS build

MAINTAINER Ente "ducksource@duckpond.ch"

# Install requirements to clone repository and install deps
RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      git \
      nodejs npm \
      wget ca-certificates \
      apache2-utils

# Install cryptpad
ARG cryptpad_version=4.2.1
ARG cryptpad_htpasswd_user="crypt"
ARG cryptpad_htpasswd_password="replaceme"
RUN set -ex \
  && wget \
    "https://github.com/xwiki-labs/cryptpad/archive/${cryptpad_version}.tar.gz" \
  && mkdir -p "/cryptpad" \
  && tar \
    -C "/cryptpad" \
    --strip-components 1 \
    -xzvf "${cryptpad_version}.tar.gz" \
  && rm "${cryptpad_version}.tar.gz" \
  && ( \
    cd "/cryptpad" \
    && npm install --production \
    && npm install -g bower \
    && bower install --allow-root \
    && htpasswd \
      -b \
      -c ./.htpasswd \
      "${cryptpad_htpasswd_user}" \
      "${cryptpad_htpasswd_password}" \
  )

# Create actual cryptpad image
FROM debian-dockerize

MAINTAINER Ente "ducksource@duckpond.ch"

# Install runtime dependencies
RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      nodejs

# Install cryptpad
COPY --from=build /cryptpad /cryptpad

# Make service writable directories
RUN set -ex \
  && SERVICE_WRITABLE_DIRS=( \
    "/cryptpad/blob" \
    "/cryptpad/block" \
    "/cryptpad/data" \
    "/cryptpad/datastore" \
  ) \
  && mkdir -p "${SERVICE_WRITABLE_DIRS[@]}" \
  && chown -R \
    "${SERVICE_USER}":"${SERVICE_GROUP}" \
    "${SERVICE_WRITABLE_DIRS[@]}"

USER "${SERVICE_UID}":"${SERVICE_USER}"

VOLUME /cryptpad

EXPOSE 3000
EXPOSE 3001

COPY start.sh .
CMD ["./start.sh"]
