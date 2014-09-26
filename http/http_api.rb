require "sinatra"
require "airbrake"
require "config/initializers/airbrake"

configure do
  Airbrake.configuration.ignore << "Sinatra::NotFound"
  use Airbrake::Sinatra
end

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
  post "/topics" do
    app.create_topic(adapter)
  end

  def adapter
    self
  end

  def created(response)
    content_type(:json)
    status(201)
    body(JSON.dump(response))
  end

  def success(response)
    content_type(:json)
    status(200)
    body(JSON.dump(response))
  end

  def unprocessible(response)
    content_type(:json)
    status(422)
    body(JSON.dump(response))
  end

  def app
    APP
  end
end
