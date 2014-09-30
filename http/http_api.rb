require "sinatra"
require "airbrake"
require "config/initializers/airbrake"

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
  end

  post "/subscriber_lists" do
    app.create_subscriber_list(adapter)
  end

  post "/notifications" do
    app.notify_subscriber_lists_by_tags(adapter)
  end

  def adapter
    self
  end

  def success(response)
    respond_json(200, response)
  end

  def created(response)
    respond_json(201, response)
  end

  def accepted(response)
    respond_json(202, response)
  end

  def unprocessable(response)
    respond_json(422, response)
  end

  def respond_json(status_code, response)
    content_type(:json)
    status(status_code)
    body(JSON.dump(response))
  end

  def app
    APP
  end
end
