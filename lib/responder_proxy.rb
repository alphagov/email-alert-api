class ResponderProxy
  def initialize(responder, callbacks ={})
    @responder = responder
    @callbacks = callbacks
  end

  def on(event, &block)
    new_callbacks = callbacks.merge(
      event => [block],
    ) { |_key, old, new| new + old }

    self.class.new(
      responder,
      new_callbacks,
    )
  end

  [
    :success,
    :created,
    :accepted,
    :unprocessable,
    :not_found,
    :missing_parameters,
  ].each do |event|
    define_method(event) do |content|
      proxy_event_with_callbacks(event, content)
    end
  end

private
  attr_reader(
    :responder,
    :callbacks,
  )

  def proxy_event_with_callbacks(event, content)
    callbacks.fetch(event, []).each { |cb| cb.call(content) }
    responder.public_send(event, content)
  end
end
