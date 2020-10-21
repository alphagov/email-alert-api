class SendEmailService::DelayProvider
  def self.call(...)
    new.call(...)
  end

  def call(**_args)
    Kernel.sleep 0.1
    Metrics.sent_to_notify_successfully
    :delivered
  end

  private_class_method :new
end
