class BulkSubscriberListEmailBuilderSubscriptions
  include Callable

  BATCH_SIZE = 5000

  def initialize(subscriber_list:)
    @subject = dbt_email_subject
    @body = dbt_email_body
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

  def dbt_email_subject
    "Your email alerts for the Department for Business and Trade have ended"
  end

  def dbt_email_body
    <<~BODY
      The Department for Business and Trade (DBT) has become the Department for Business, Innovation, Science and Trade (BIST).

      You previously signed up to email alerts for DBT. As DBT has been replaced by BIST, you will no longer receive email alerts for new and updated GOV.UK pages relating to DBT.

      If you’d like to receive updates about the work of BIST, you can [sign up for email alerts from BIST](https://www.gov.uk/email-signup?link=/government/organisations/department-for-business-innovation-science-and-trade).
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
