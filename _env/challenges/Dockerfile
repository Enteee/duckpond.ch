FROM debian-dockerize

# Install python
ARG python_version=3.7.3-1
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
      apt-get install --no-install-recommends --no-install-suggests -y \
        python3="${python_version}"

ADD one-time-pad one-time-pad
ADD one-time-pad-2 one-time-pad-2

USER "${SERVICE_UID}":"${SERVICE_USER}"

EXPOSE 8888
EXPOSE 8889

COPY start.sh .
CMD ["./start.sh"]
