class UnpublishEmailBuilder
  def self.call(*args)
    new.call(*args)
  end

  def call(emails, template)
    Email.import!(email_records(emails, template)).ids
  end

private

  def email_records(email_parameters, template)
    email_parameters.map do |email|
      {
        address: email.subscriber.address,
        subject: "Update from GOV.UK – #{email.subject}",
        body: ERB.new(template).result(
          EmailTemplateContext.new(
            email.template_data,
          ).fetch_binding,
        ),
        subscriber_id: email.subscriber.id,
      }
    end
  end
end
