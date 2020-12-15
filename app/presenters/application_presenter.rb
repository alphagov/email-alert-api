class ApplicationPresenter
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new
end
