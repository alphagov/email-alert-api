class BulkSubscriberListEmailBuilderSubscriptions
  include Callable

  BATCH_SIZE = 5000

  def initialize(subscriber_list:)
    @subject = dsit_email_subject
    @body = dsit_email_body
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

  def dsit_email_subject
    "Your email alerts for the Department for Science, Innovation and Technology have ended"
  end

  def dsit_email_body
    <<~BODY
      The Department for Science, Innovation and Technology (DSIT) has now been closed. Some parts have been merged into the Department for Business, Innovation, Science and Trade (BIST) and some merged into the Department for Digital, Culture, Media and Sport (DCMS). Some DSIT responsibilities for AI have moved to the Cabinet Office.

      If you would like to receive updates about digital related work and groups, such as cyber security, digital identity, digital infrastructure or the Government Digital Service, you can [sign up for email alerts from DCMS](https://www.gov.uk/email-signup?link=/government/organisations/department-for-digital-culture-media-and-sport).

      If you would like to receive updates about science related work and groups, such as scientific growth, investment and engagement, the Government Office for Science or the UK Space Agency, you can [sign up for email alerts from BIST](https://www.gov.uk/email-signup?link=/government/organisations/department-for-business-innovation-science-and-trade).

      If you would like to receive updates about AI strategy, public sector AI adoption or the AI Security Institute, you can [sign up for email alerts from the Cabinet Office](https://www.gov.uk/email-signup?link=/government/organisations/cabinet-office).
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
