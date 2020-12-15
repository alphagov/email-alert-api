class UnpublishEmailBuilder < ApplicationBuilder
  def initialize(email_parameters, template)
    @email_parameters = email_parameters
    @template = template
  end

  def call
    Email.insert_all!(email_records).pluck("id")
  end

private

  attr_reader :email_parameters, :template

  def email_records
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
