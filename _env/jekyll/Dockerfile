FROM jekyll/jekyll

MAINTAINER Ente "ducksource@duckpond.ch"

COPY start.sh .

RUN set -ex \ 
  && echo 'http://dl-cdn.alpinelinux.org/alpine/v3.5/main' >> /etc/apk/repositories \
  && apk --no-cache add \
    imagemagick-dev=6.9.6.8-r1 \
  && gem install \
    jekyll-responsive-image

CMD ["./start.sh"]
