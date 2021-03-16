ARG debian_version=10.0
FROM debian:${debian_version} AS build

# Install requirements to clone repository and install deps
RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      git \
      nodejs npm \
      wget ca-certificates \
      apache2-utils

# Install dockerize
ARG dockerize_version=0.6.1
RUN set -ex \
  && wget \
    "https://github.com/jwilder/dockerize/releases/download/v${dockerize_version}/dockerize-linux-amd64-v${dockerize_version}.tar.gz" \
  && tar -C "/usr/local/bin" -xzvf "dockerize-linux-amd64-v${dockerize_version}.tar.gz" \
  && rm "dockerize-linux-amd64-v${dockerize_version}.tar.gz"

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
FROM debian:${debian_version}

# Install runtime dependencies
RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      inotify-tools \
      nodejs

# Copy dockerize from build
COPY --from=build /usr/local/bin/dockerize /usr/local/bin/dockerize

# Copy cryptpad from build
COPY --from=build /cryptpad /cryptpad

# Ports
EXPOSE 3000 3001

COPY start.sh .

VOLUME /cryptpad

ENTRYPOINT [ "dockerize" ]
CMD ["true"]
