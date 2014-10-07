require "forwardable"
require "json"

class SinatraAdapter
  def initialize(sinatra_app)
    @sinatra_app = sinatra_app
  end

  def params
    sinatra_app.params.except(*junk_params)
  end

  def responder
    Responder.new(sinatra_app)
  end

  private

  attr_reader :sinatra_app

  def junk_params
    %w(
      captures
      splat
    )
  end

  class Responder
    extend Forwardable

    def initialize(sinatra_app)
      @sinatra_app = sinatra_app
    end

    def success(content)
      respond_with_json(200, content)
    end

    def created(content)
      respond_with_json(201, content)
    end

    def accepted(content)
      respond_with_json(202, content)
    end

    def unprocessable(content)
      respond_with_json(422, content)
    end

    def not_found(content)
      respond_with_json(404, content)
    end

    def missing_parameters(args = {})
      unprocessable(args)
    end

    private

    attr_reader :sinatra_app

    def_delegators :sinatra_app, :status, :body, :content_type

    def respond_with_json(status, content)
      status(status)
      content_type :json
      body(JSON.dump(content))
      return_nil_so_sinatra_does_not_double_render
    end

    def return_nil_so_sinatra_does_not_double_render
      return nil # so sinatra does not double render
    end
  end
end
