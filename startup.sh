#!/usr/bin/env sh

gem install foreman --conservative
bundle install
PORT=${PORT:-3088} foreman start
