# rubocop:disable Metrics/BlockLength

module BulkUnsubscribeService
  def self.call(
        content_ids_and_replacements,
        subscriber_limit: 1_000_000,
        courtesy_emails_every_nth_email: 500
      )
    affected_subscriber_list_ids = content_ids_and_replacements
                                     .keys
                                     .flat_map do |content_id|
      SubscriberList.find_by_links_value(content_id).pluck(:id)
    end

    subscriptions_to_end = Subscription
                             .where(subscriber_list_id: affected_subscriber_list_ids)
                             .includes(:subscriber)
                             .active

    subscriptions_to_end
      .group_by(&:subscriber)
      .sort_by { |_subscriber, subscriptions| subscriptions.length * -1 } # start with most subscriptions
      .take(subscriber_limit)
      .each_with_index do |(subscriber, subscriptions), index|

      subscription_details = subscriptions.map do |subscription|
        relevant_content_id = subscription
                                .subscriber_list
                                .links
                                .values
                                .flatten
                                .find do |links_content_id|
          content_ids_and_replacements.key? links_content_id
        end

        [
          subscription.subscriber_list.title,
          content_ids_and_replacements.fetch(relevant_content_id)
        ]
      end

      subscription_details = subscription_details.sort_by do |(title, _replacement)|
        title
      end

      email = nil
      ActiveRecord::Base.transaction do
        email = process_subscriber(
          subscriber,
          subscription_details,
          send_courtesy_copy: (index % courtesy_emails_every_nth_email).zero?
        )

        UnsubscribeService.subscriptions!(
          subscriber,
          subscriptions,
          :unpublished,
          ended_email_id: email.id
        )
      end

      DeliveryRequestWorker.perform_async_in_queue(
        email.id,
        queue: :delivery_immediate
      )
    end
  end

  def self.process_subscriber(
        subscriber,
        subscription_details,
        send_courtesy_copy:
      )
    subject = 'Changes to your email subscriptions'
    template_data = {
      subscription_details: subscription_details,
      utm_parameters: {
        'utm_source' => subject,
        'utm_medium' => 'email',
        'utm_campaign' => 'govuk-subscription-ended'
      }
    }

    email = BulkUnsubscribeEmailBuilder.call(
      EmailParameters.new(
        subject: subject,
        subscriber: subscriber,
        template_data: template_data
      ),
      BULK_POLICY_TEMPLATE
    )

    if send_courtesy_copy
      Subscriber.where(
        address: Email::COURTESY_EMAIL
      ).each do |courtesy_subscriber|
        courtesy_email = BulkUnsubscribeEmailBuilder.call(
          EmailParameters.new(
            subject: subject,
            subscriber: courtesy_subscriber,
            template_data: template_data
          ),
          BULK_POLICY_TEMPLATE
        )

        DeliveryRequestWorker.perform_async_in_queue(
          courtesy_email.id,
          queue: :delivery_immediate
        )
      end
    end

    email
  end

  BULK_POLICY_TEMPLATE = <<~BODY.freeze
    We're changing the way content is organised on GOV.​UK. This affects your email subscriptions.

    You are subscribed to email updates about <%= pluralize(subscription_details.length, 'policy page') %>. You will not receive these updates any more.

    You can sign up to <%= subscription_details.length == 1 ? 'this topic' : 'these topics' %> to get similar updates:
    <% subscription_details.each do |(subscription_title, replacement)| %>
      - [<%= replacement.title %>](<%= add_utm(replacement.url, utm_parameters) %>)
    <% end %>
  BODY
end

# rubocop:enable Metrics/BlockLength
