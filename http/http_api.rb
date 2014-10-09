require "sinatra"
require "airbrake"
require "config/initializers/airbrake"
require "sinatra_adapter"
require "middleware/post_body_content_type_parser"

# TODO: Disable ShowExceptions in a less gross way, do we care about development mode?
Sinatra::ShowExceptions.class_eval do
  def prefers_plain_text?(_env)
    true
  end

  def call(env)
    @app.call(env)
  end
end

class HTTPAPI < Sinatra::Application
  configure do
    Airbrake.configuration.ignore << "Sinatra::NotFound"
    use Airbrake::Sinatra

    use Rack::PostBodyContentTypeParser
  end

  post "/subscriber_lists" do
    app.create_subscriber_list(adapter)
  end

  get "/subscriber_lists" do
    app.search_subscriber_lists(adapter)
  end

  post "/notifications" do
    app.notify_subscriber_lists_by_tags(adapter)
  end

  def adapter
    SinatraAdapter.new(self)
  end

  def app
    APP
  end
end
