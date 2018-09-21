class EmailParameters
  attr_reader :subject, :subscriber, :template_data

  def initialize(subscriber:, subject:, template_data: {})
    @subscriber = subscriber
    @subject = subject
    @template_data = template_data.merge(
      subject: subject,
      address: subscriber.address
    )
  end
end
