FROM wonderfall/isso

MAINTAINER Ente "ducksource@duckpond.ch"

COPY wait .
ENTRYPOINT ["./wait"]
CMD ["/sbin/tini","--","run.sh"]
