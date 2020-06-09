class DelayProvider
  def self.call(*args)
    new.call(*args)
  end

  def call(**_args)
    Kernel.sleep 0.1
    MetricsService.sent_to_notify_successfully
    :delivered
  end

  private_class_method :new
end
