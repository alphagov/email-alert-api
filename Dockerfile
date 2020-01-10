FROM ruby:2.7.0
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libxml2-dev \
  libxslt1-dev
RUN apt-get clean
RUN gem install foreman

ENV DATABASE_URL postgresql://postgres@postgres/email-alert-api
ENV GOVUK_APP_NAME email-alert-api
ENV PORT 3088
ENV RAILS_ENV development
ENV REDIS_HOST redis
ENV TEST_DATABASE_URL postgresql://postgres@postgres/email-alert-api-test

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD foreman run web
