FROM ruby:2.7.2
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libxml2-dev \
  libxslt1-dev
RUN apt-get clean
RUN gem install foreman

# This image is only intended to be able to run this app in a production RAILS_ENV
ENV RAILS_ENV production

ENV DATABASE_URL postgresql://postgres@postgres/email-alert-api
ENV GOVUK_APP_NAME email-alert-api
ENV PORT 3088

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle config set deployment 'true'
RUN bundle config set without 'development test'
RUN bundle install --jobs 4
ADD . $APP_HOME

CMD foreman run web
