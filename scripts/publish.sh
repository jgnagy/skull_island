#!/bin/sh

SI_VERSION=`grep skull_island Gemfile.lock | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'`
docker tag skull_island:local jgnagy/skull_island:$SI_VERSION
docker tag skull_island:local jgnagy/skull_island:latest
docker push jgnagy/skull_island:$SI_VERSION
docker push jgnagy/skull_island:latest
