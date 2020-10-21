class UnpublishEmailBuilder
  def self.call(...)
    new.call(...)
  end

  def call(emails, template)
    records = email_records(emails, template)
    Email.insert_all!(records).pluck("id")
  end

private

  def email_records(email_parameters, template)
    now = Time.zone.now
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
        created_at: now,
        updated_at: now,
      }
    end
  end
end
