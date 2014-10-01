module BareAppIntegrationHelpers
  def bare_app
    APP
  end

  def null_context(*args)
    NullContext.new(*args)
  end
end
