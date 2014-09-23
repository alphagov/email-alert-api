require "sinatra"

# TODO Make this work
Sinatra::ShowExceptions.class_eval do
  def prefers_plain_text?(_env)
    true
  end
end

class HTTPAPI < Sinatra::Application
  post "/topics" do
    app.create_topic(adapter)
  end

  def adapter
    self
  end

  def success(response)
    content_type(:json)
    status(200)
    body(JSON.dump(response))
  end

  def app
    APP
  end
end
