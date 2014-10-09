class ValidInputFilter
  def initialize(service:, responder:, validators:)
    @service = service
    @responder = responder
    @validators = validators
  end

  def call
    if input_valid?
      service.call(responder)
    else
      responder.unprocessable(error: error_message)
    end
  end

private
  attr_reader(
    :service,
    :responder,
    :validators,
  )

  def input_valid?
    validators.all?(&:valid?)
  end

  def error_message
    "Request rejected due to invalid parameters"
  end
end
