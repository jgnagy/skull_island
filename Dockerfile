FROM ruby:2.5-alpine
LABEL maintainer="Jonathan Gnagy <jonathan.gnagy@gmail.com>"

RUN apk add build-base \
    && gem install skull_island \
    && apk del build-base \
    && rm -rf /var/cache/apk/*

ENTRYPOINT ["skull_island"]
