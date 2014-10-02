class ValidInputFilter
  def initialize(service:, context:, validators:)
    @service = service
    @context = context
    @validators = validators
  end

  def call
    if input_valid?
      service.call(context)
    else
      context.unprocessable(error: error_message)
    end
  end

private
  attr_reader(
    :service,
    :context,
    :validators,
  )

  def input_valid?
    validators.all?(&:valid?)
  end

  def error_message
    "A subscriber list was not created due to invalid attributes"
  end
end
