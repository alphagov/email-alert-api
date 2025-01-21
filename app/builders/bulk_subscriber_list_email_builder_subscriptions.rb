class BulkSubscriberListEmailBuilderSubscriptions
  include Callable

  BATCH_SIZE = 5000

  def initialize(subscriber_list:)
    case subscriber_list.slug
    when "central-digital-and-data-office"
      @subject = cddo_email_subject
      @body = cddo_email_body
    when "geospatial-commission"
      @subject = geospatial_email_subject
      @body = geospatial_email_body
    when "incubator-for-artificial-intelligence"
      @subject = ai_email_subject
      @body = ai_email_body
    end

    @subscriber_lists = subscriber_list
    @now = Time.zone.now
  end

  def call
    ActiveRecord::Base.transaction do
      batches.flat_map do |subscription_ids|
        records = records_for_batch(subscription_ids)
        records.empty? ? [] : Email.insert_all!(records).pluck("id")
      end
    end
  end

  def cddo_email_subject
    "Your email alerts about the Central Digital and Data Office have ended"
  end

  def cddo_email_body
    <<~BODY
      The Central Digital and Data Office (CDDO) has merged with the Geospatial Commission, the Government Digital Service (GDS) and the Incubator for Artificial Intelligence (i.AI) to create the new Government Digital Service - the digital centre of government, part of the Department for Science, Innovation and Technology (DSIT).

      The Government Digital Service now leads the Government Digital and Data function for government.

      You will no longer receive email alerts for new and updated GOV.UK pages related to the Central Digital and Data Office.

      If you would like to receive updates about the work of the Government Digital Service, you can [sign up for email alerts](https://www.gov.uk/email-signup?link=/government/organisations/government-digital-service).
    BODY
  end

  def geospatial_email_subject
    "Your email alerts about the Geospatial Commission have ended"
  end

  def geospatial_email_body
    <<~BODY
      The Geospatial Commission is merging with the Central Digital and Data Office (CDDO), the Government Digital Service (GDS) and the Incubator for Artificial Intelligence (i.AI) to create the new Government Digital Service - the digital centre of government, part of the Department for Science, Innovation and Technology (DSIT).

      You will no longer receive email alerts for new and updated GOV.UK pages related to the Geospatial Commission.

      If you would like to receive updates about the work of the Government Digital Service, you can [sign up for email alerts](https://www.gov.uk/email-signup?link=/government/organisations/government-digital-service).
    BODY
  end

  def ai_email_subject
    "Your email alerts about the Incubator for Artificial Intelligence have ended"
  end

  def ai_email_body
    <<~BODY
      The Incubator for Artificial Intelligence (i.AI) is merging with the Central Digital and Data Office (CDDO), the Geospatial Commission and the Government Digital Service (GDS) to create the new Government Digital Service - the digital centre of government, part of the Department for Science, Innovation and Technology (DSIT).

      You will no longer receive email alerts for new and updated GOV.UK pages related to the Incubator for Artificial Intelligence.

      If you would like to receive updates about the work of the Government Digital Service, you can [sign up for email alerts](https://www.gov.uk/email-signup?link=/government/organisations/government-digital-service).
    BODY
  end

private

  attr_reader :subject, :body, :subscriber_lists, :now

  def records_for_batch(subscription_ids)
    subscriptions = Subscription
      .includes(:subscriber, :subscriber_list)
      .find(subscription_ids)

    filtered_subscriptions = filter_subscriptions(subscriptions)

    filtered_subscriptions.map do |subscription|
      subscriber = subscription.subscriber

      {
        address: subscriber.address,
        subject:,
        body: email_body(subscriber, subscription),
        subscriber_id: subscriber.id,
        created_at: now,
        updated_at: now,
      }
    end
  end

  def filter_subscriptions(subscriptions)
    subscriptions.reject { |sub| Services.accounts_emails.include?(sub.subscriber.address) }
  end

  def email_body(subscriber, subscription)
    <<~BODY
      #{BulkEmailBodyPresenter.call(body, subscription.subscriber_list)}

      ---

      #{FooterPresenter.call(subscriber, subscription)}
    BODY
  end

  def batches
    Subscription
      .active
      .where(subscriber_list: subscriber_lists)
      .dedup_by_subscriber
      .each_slice(BATCH_SIZE)
  end
end
