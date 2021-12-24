class UnpublicationNotificationBuilder
  include Callable

  BATCH_SIZE = 5000

  def initialize(subscriber_list:, notification_template:)
    @subscriber_list = subscriber_list
    @notification_template = notification_template
  end

  def call
    ActiveRecord::Base.transaction do
      batches.flat_map do |subscription_ids|
        records = records_for_batch(subscription_ids)
        records.empty? ? [] : Email.insert_all!(records).pluck("id")
      end
    end
  end

private

  attr_reader :notification_template

  def subject
    "Update from GOV.UK for: #{page_title}"
  end

  def body
    <<~BODY
      #{title_and_optional_url}

      ---

      #{presented_results}

      #{I18n.t("emails.unpublication_notification.footer_notice")}
    BODY
  end

  def content_item
    # TODO - content_id is not going to be enough, we're going to need more information.
    # Specifically:
    # - time_content_updated (2/3 cases)
    # - page_summary
    # - title
    # - url
    # - alternative_url
    #
    # Initially the plan was to pass the ID through here and then see if we could query the content
    # store to pull the data up here. However I'm now wonder creating a new interdependcy at this point
    # is the best way? Our other option would be to either emit the data we need as a part of the event
    # from publishing_api and pass it along in the POST requets...
    # Or perhaps email-alert-service could gather the information and post it along?
    content_id = subscriber_list.content_id
    # content_item = Services
  end

  def title_and_optional_url
    result = title

    # @TODO - check what this URL might be for each case
    # In the content doc: https://docs.google.com/document/d/1xUxJ3GbGzZwUIvuY2b-D-mMCxGMDqCv5pD9ensoaMDc/edit#
    # It seems we have based these off change notifications.
    # However, here, what this URL / title is is less clear?
    # Should it reflect what the page was called / the old URL? Or does it reflect
    # the newly updated data?
    # In either case, will there actually be a content item we can query or will it have been moved to the draft stack?
    source_url = SourceUrlPresenter.call(
      subscriber_list.url,
      utm_source: subscriber_list.slug,
      utm_content: "confirmation",
    )

    result += "\n\n#{source_url}" if source_url
    result
  end

  def presented_results
    changes = content.map do |item|
      UnsubscriptionNotificationPresenter.call(content_item, notification_template)
    end

    changes.join("\n\n---\n\n").strip
  end

  def records_for_batch(subscription_ids)
    subscriptions = Subscription
      .includes(:subscriber, :subscriber_list)
      .find(subscription_ids)

      subscriptions.map do |subscription|
      subscriber = subscription.subscriber

      {
        address: subscriber.address,
        subject: subject,
        body: body,
        subscriber_id: subscriber.id,
        created_at: now,
        updated_at: now,
      }
    end
  end

  def batches
    Subscription
      .active
      .where(subscriber_list: subscriber_list)
      .dedup_by_subscriber
      .each_slice(BATCH_SIZE)
  end
end
