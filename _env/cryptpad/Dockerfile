FROM debian-dockerize AS build

# Install requirements to clone repository and install deps
RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      git \
      wget curl ca-certificates \
      apache2-utils

# Install recent nodejs
ARG nodejs_version=15.14.0-1nodesource1
RUN set -ex \
  && nodejs_version_major="$(echo "${nodejs_version}" | cut -d. -f1)" \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      ca-certificates \
      curl \
      gnupg \
      unzip \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${nodejs_version_major}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
  && apt-get update
# break here for fetching new nodejs_version
RUN set -ex \
  && DEBIAN_FRONTEND=noninteractive \
    apt-cache policy nodejs \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      nodejs=${nodejs_version}

# Install cryptpad
ARG cryptpad_archive="https://github.com/xwiki-labs/cryptpad/archive"
ARG cryptpad_version=4.2.1
ARG cryptpad_htpasswd_user="crypt"
ARG cryptpad_htpasswd_password="replaceme"
COPY patches /patches
RUN set -ex \
  && wget \
    --no-verbose \
    --show-progress \
    --progress=dot:giga \
    "${cryptpad_archive}/${cryptpad_version}.tar.gz" \
  && mkdir -p "/cryptpad" \
  && tar \
    -C "/cryptpad" \
    --strip-components 1 \
    -xzf "${cryptpad_version}.tar.gz" \
  && rm "${cryptpad_version}.tar.gz" \
  && ( \
    cd "/cryptpad" \
    && ( \
      shopt -s nullglob; \
      for p in /patches/* ; do git apply "${p}"; done \
    ) \
    && npm install --omit=dev \
    && npm run install:components \
    && npm run build \
    && ./install-onlyoffice.sh \
      --accept-license \
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
      curl ca-certificates

# Install recent nodejs
ARG nodejs_version=15.14.0-1nodesource1
RUN set -ex \
  && nodejs_version_major="$(echo "${nodejs_version}" | cut -d. -f1)" \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      ca-certificates \
      curl \
      gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${nodejs_version_major}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
  && apt-get update
# break here for fetching new nodejs_version
RUN set -ex \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      nodejs=${nodejs_version}

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
