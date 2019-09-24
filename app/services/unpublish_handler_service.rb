class UnpublishHandlerService
  TAXON_TEMPLATE = <<~BODY.freeze
    Your subscription to email updates about '<%=subject%>' has ended because this topic no longer exists on GOV.UK.

    You might want to subscribe to updates about '<%=redirect.title%>' instead: [<%=redirect.url%>](<%=add_utm(redirect.url, utm_parameters)%>)

    <%=presented_manage_subscriptions_links(address)%>
  BODY

  POLICY_AND_POLICY_AREA_TEMPLATE = <<~BODY.freeze
    We're changing the way content is organised on GOV.UK.

    Because of this, you will not get email updates about '<%= subject %>' anymore.

    If you want to continue receiving updates relating to this topic, you can [subscribe to the new '<%= redirect.title %>' page](<%= add_utm(redirect.url, utm_parameters) %>).

    <%=presented_manage_subscriptions_links(address)%>
  BODY

  TEMPLATES = {
    taxon_tree: TAXON_TEMPLATE,
    policy_areas: POLICY_AND_POLICY_AREA_TEMPLATE,
    policies: POLICY_AND_POLICY_AREA_TEMPLATE,
  }.freeze

  def self.call(*args)
    new.call(*args)
  end

  def call(content_id, redirect)
    subscriber_lists = SubscriberList
                         .find_by_links_value(content_id)
                         .includes(:subscribers)
    type = find_type(subscriber_lists, content_id)
    template = TEMPLATES[type]

    return unless template

    subscriber_lists.each do |subscriber_list|
      any_emails_sent = process_subscriber_list(subscriber_list, redirect, template)

      send_courtesy_emails(subscriber_list, redirect, template) if any_emails_sent
    end
  end

private

  def process_subscriber_list(subscriber_list, redirect, template)
    subscriptions = subscriber_list
                      .subscriptions
                      .includes(:subscriber)
                      .active

    email_parameters = subscriptions.map do |subscription|
      subscriber = subscription.subscriber

      EmailParameters.new(
        subject: subscriber_list.title,
        subscriber: subscriber,
        template_data: {
          redirect: redirect,
          utm_parameters: {
            "utm_source" => subscriber_list.title,
            "utm_medium" => "email",
            "utm_campaign" => "govuk-subscription-ended",
          },
        },
      )
    end

    return false if email_parameters.empty?

    email_ids = UnpublishEmailBuilder.call(email_parameters, template)

    email_ids.zip(subscriptions) do |email_id, subscription|
      DeliveryRequestWorker.perform_async_in_queue(
        email_id,
        queue: :delivery_immediate,
      )

      subscription.update!(
        ended_reason: :unpublished,
        ended_at: Time.now,
        ended_email_id: email_id,
      )
    end

    SubscriberDeactivationWorker.perform_async(
      subscriptions.map(&:subscriber_id),
    )

    true
  end

  def send_courtesy_emails(subscriber_list, redirect, template)
    email_parameters = Subscriber.where(
      address: Email::COURTESY_EMAIL,
    ).map do |subscriber|
      EmailParameters.new(
        subject: subscriber_list.title,
        subscriber: subscriber,
        template_data: {
          redirect: redirect,
          utm_parameters: {},
        },
      )
    end

    email_ids = UnpublishEmailBuilder.call(email_parameters, template)

    email_ids.each do |email_id|
      DeliveryRequestWorker.perform_async_in_queue(
        email_id,
        queue: :delivery_immediate,
      )
    end
  end

  def find_type(subscriber_lists, content_id)
    first_list = subscriber_lists.first
    return :none if first_list.nil?

    first_list.links.find { |_, values| (values.fetch(:any, []) + values.fetch(:all, [])).include?(content_id) }.first
  end
end
