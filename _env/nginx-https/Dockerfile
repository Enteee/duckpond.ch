FROM nginx

MAINTAINER Ente "ducksource@duckpond.ch"

COPY wait .
ENTRYPOINT ["./wait"]
CMD ["nginx", "-g" ,"daemon off;"]
