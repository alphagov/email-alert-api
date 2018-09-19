class BulkUnsubscribeEmailBuilder
  def initialize(email_parameters, template)
    @email_parameters = email_parameters
    @template = template
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.create!(
      subject: email_parameters.subject,
      body: body,
      address: email_parameters.subscriber.address,
      subscriber_id: email_parameters.subscriber.id,
    )
  end

  private_class_method :new

private

  attr_reader :email_parameters, :template

  def body
    ERB.new(template).result(
      EmailTemplateContext.new(
        email_parameters.template_data
      ).fetch_binding
    )
  end
end
