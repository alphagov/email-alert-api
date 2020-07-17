class ApplicationService
  def self.call(*args)
    new(*args).call
  end

  private_class_method :new
end
