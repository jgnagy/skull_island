#!/bin/sh

gem install bundler -v '~> 2.2'
bundle install
bundle exec rake
