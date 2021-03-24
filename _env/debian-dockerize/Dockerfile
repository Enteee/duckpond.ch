ARG debian_version=10.0
FROM debian:${debian_version} AS build

MAINTAINER Ente "ducksource@duckpond.ch"

# Build dockerize
ARG dockerize_version=0.6.1
RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      wget ca-certificates \
      inotify-tools \
  && wget \
    "https://github.com/jwilder/dockerize/releases/download/v${dockerize_version}/dockerize-linux-amd64-v${dockerize_version}.tar.gz" \
  && tar -C "/usr/local/bin" -xzvf "dockerize-linux-amd64-v${dockerize_version}.tar.gz" \
  && rm "dockerize-linux-amd64-v${dockerize_version}.tar.gz"

FROM debian:${debian_version}

# Install dockerize
RUN set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --no-install-suggests -y \
      inotify-tools
COPY --from=build  /usr/local/bin/dockerize /usr/local/bin/dockerize

# Create user & group
ARG service_gid=100
ENV SERVICE_GID=${service_gid}
ARG service_group=service
ENV SERVICE_GROUP=${service_group}
ARG service_uid=1000
ENV SERVICE_UID=${service_uid}
ARG service_user=service
ENV SERVICE_USER=${service_user}
ARG service_user_home=/service
ENV SERVICE_USER_HOME=${service_user_home}
RUN set -exu \
  && if getent passwd "${service_user}"; then \
    userdel "${service_user}" ;\
  fi \
  && if getent group "${service_group}"; then \
    groupdel "${service_group}" ;\
  fi \
  && groupadd \
    --force \
    --gid "${service_gid}" \
    "${service_group}" \
  && useradd \
      --uid "${service_uid}" \
      --gid "${service_gid}" \
      --home-dir "${service_user_home}" \
      "${service_user}" \
  && mkdir -p "${service_user_home}" \
  && chown -R \
    "${service_user}:${service_group}" \
    "${service_user_home}"
WORKDIR "${service_user_home}"

# Do switch user context later
#USER "${SERVICE_UID}":"${SERVICE_USER}"

SHELL ["/bin/bash", "-c"]

ENTRYPOINT [ "dockerize" ]
CMD [ "true" ]
