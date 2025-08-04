FROM debian-dockerize

# Install nginx
ARG nginx_version="1.14.2-2+deb10u3"
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
      apt-get install --no-install-recommends --no-install-suggests -y \
        nginx="${nginx_version}"

# Run nginx as root
#USER "${SERVICE_UID}":"${SERVICE_USER}"

EXPOSE 443

COPY start.sh .
CMD ["./start.sh"]
