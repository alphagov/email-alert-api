class NullContext
  def initialize(params: {})
    @params = params
  end

  attr_reader :params

  def responder
    Responder.new
  end

  class Responder
    def created(response)
      response
    end

    def unprocessable(response)
      response
    end
  end
end
