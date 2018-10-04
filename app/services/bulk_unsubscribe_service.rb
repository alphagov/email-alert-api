# rubocop:disable Metrics/BlockLength

module BulkUnsubscribeService
  mattr_accessor :people, :world_locations, :organisations, :policy_area_mappings, :taxonomy

  def self.person_slug(content_id)
    result = people.find(-> { {} }) { |person| person[:content_id] == content_id }
    result[:slug]
  end

  def self.world_location_slug(content_id)
    result = world_locations.find(-> { {} }) { |world_location| world_location[:content_id] == content_id }
    result[:slug]
  end

  def self.organisation_slug(content_id)
    result = organisations.find(-> { {} }) { |org| org[:content_id] == content_id }
    result[:slug]
  end

  def self.taxon_path(policy_area_content_id)
    result = policy_area_mappings.find(-> { {} }) { |mapping| mapping[:content_id] == policy_area_content_id }
    result[:taxon_path]
  end

  def self.call(
        subscriber_limit: 1_000_000,
        courtesy_emails_every_nth_email: 500,
        people: [], #[{content_id: ..., slug: ....}]
        world_locations: [], #[{content_id: ..., slug: ....}]
        organisations: [], #[{content_id: ..., slug: ....}]
        policy_area_mappings: [] #[{content_id: ...., policy_area_path: ... taxon_path: ....}]
    )

    BulkUnsubscribeService.people = people
    BulkUnsubscribeService.world_locations = world_locations
    BulkUnsubscribeService.organisations = organisations
    BulkUnsubscribeService.policy_area_mappings = policy_area_mappings
    BulkUnsubscribeService.taxonomy = Taxonomy.new

    affected_subscriber_list_ids = policy_area_mappings.flat_map do |mapping|
      SubscriberList.find_by_links_value(mapping[:content_id]).pluck(:id)
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
        subscription_content_ids = subscription
                                .subscriber_list
                                .links
                                .values
                                .flatten
        mapping = policy_area_mappings.find { |m| subscription_content_ids.include?(m[:content_id]) }
        SubscriptionDetails.new(subscription, mapping[:policy_area_path], mapping[:taxon_path])
      end

      subscription_details.sort_by!(&:title)

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

    You are subscribed to email updates about <%= pluralize(subscription_details.length, 'policy area') %>. You will not receive these updates any more.

    You can get similar updates by signing up to:
    <% subscription_details.each do |details| %>
      - [<%= details.replacement_title %>](<%= add_utm(details.replacement_url, utm_parameters) %>)
    <% end %>
  BODY
end

# rubocop:enable Metrics/BlockLength
