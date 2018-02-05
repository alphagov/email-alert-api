#!/usr/bin/env sh

bundle install
PORT=${PORT:-3088} bundle exec foreman start
