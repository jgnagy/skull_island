FROM ruby:2.5-alpine
LABEL maintainer="Jonathan Gnagy <jonathan.gnagy@gmail.com>"

COPY . /install

RUN apk add build-base git \
    && cd /install \
    && gem build skull_island.gemspec \
    && gem install skull_island*.gem \
    && rm skull_island*.gem \
    && apk del build-base git \
    && rm -rf /var/cache/apk/* \
    && cd / \
    && rm -rf /install

ENTRYPOINT ["skull_island"]
