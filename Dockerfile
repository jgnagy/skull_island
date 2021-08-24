FROM ruby:3.0
LABEL maintainer="Jonathan Gnagy <jonathan.gnagy@gmail.com>"

COPY . /install

RUN cd /install \
    && gem build skull_island.gemspec \
    && gem install skull_island*.gem \
    && rm skull_island*.gem \
    && cd / \
    && rm -rf /install

ENTRYPOINT ["skull_island"]
