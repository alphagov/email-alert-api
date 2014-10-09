# Taken from rack-contrib here:
# https://github.com/rack/rack-contrib/blob/281be2899d3d9bdb159e6bf6b9179d2d89354aaa/lib/rack/contrib/post_body_content_type_parser.rb
#
# TODO: Delete this code once above commit is released for rack-contrib
# Current released version of rack-contrib (v1.1.0) does not take into account
# an empty String as content body.

require 'json'

module Rack
  class PostBodyContentTypeParser

    CONTENT_TYPE = 'CONTENT_TYPE'.freeze
    POST_BODY = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH = 'rack.request.form_hash'.freeze

    APPLICATION_JSON = 'application/json'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      if Rack::Request.new(env).media_type == APPLICATION_JSON && (body = env[POST_BODY].read).length != 0
        env[POST_BODY].rewind
        env.update(FORM_HASH => JSON.parse(body), FORM_INPUT => env[POST_BODY])
      end
      @app.call(env)
    end

  end
end
