class UnpublishHandlerService
  def self.call(*args)
    new.call(*args)
  end

  def call(content_id, redirect)
    subscriber_lists = fetch_subscriber_lists(content_id)
    type = find_type(subscriber_lists, content_id)
    case type
    when :taxon_tree
      unsubscribe(subscriber_lists, redirect, taxon_template)
    when :policy_areas
      unsubscribe(subscriber_lists, redirect, policy_and_policy_area_template)
    when :policies
      unsubscribe(subscriber_lists, redirect, policy_and_policy_area_template)
    else
      log_non_taxon_lists(subscriber_lists)
    end
  end

private

  def unsubscribe(subscriber_lists, redirect, template)
    email_parameters = build_emails(subscriber_lists, redirect)
    all_email_parameters = email_parameters + courtesy_emails(email_parameters)

    emails = UnpublishEmailBuilder.call(all_email_parameters, template)
    queue_delivery_request_workers(emails)
    log_emails(emails)
    unsubscribe_list(subscriber_lists)
  end

  def unsubscribe_list(subscriber_lists)
    subscriber_lists.each do |subscriber_list|
      UnsubscribeSubscriberListWorker.perform_async(subscriber_list.id, :unpublished)
    end
  end

  def queue_delivery_request_workers(emails)
    emails.each do |email|
      DeliveryRequestWorker.perform_async_in_queue(
        email.id, queue: :delivery_immediate
      )
    end
  end

  def find_type(subscriber_lists, content_id)
    first_list = subscriber_lists.first
    return :none if first_list.nil?
    first_list.links.find { |_, values| values.include?(content_id) }.first
  end

  # For this query to return the content id has to be wrapped in a double quote blame psql 9.3
  def fetch_subscriber_lists(content_id)
    sql = <<~SQLSTRING
      :id IN (
        SELECT json_array_elements((json_each(links)).value)::text
       )
    SQLSTRING
    SubscriberList
      .where(sql, id: "\"#{content_id}\"")
      .includes(:subscribers)
  end

  def build_emails(subscriber_lists, redirect)
    subscriber_lists.flat_map do |subscriber_list|
      subscriber_list.subscribers.activated.map do |subscriber|
        EmailParameters.new(
          subject: subscriber_list.title,
          address: subscriber.address,
          subscriber_id: subscriber.id,
          redirect: redirect,
          utm_parameters: {
              'utm_source' => subscriber_list.title,
              'utm_medium' => 'email',
              'utm_campaign' => 'govuk-subscription-ended'
          }
        )
      end
    end
  end

  def courtesy_emails(taxon_emails)
    return [] if taxon_emails.empty?
    Subscriber.where(address: Email::COURTESY_EMAIL).map do |subscriber|
      EmailParameters.new(
        subject: taxon_emails.first.subject,
        address: subscriber.address,
        subscriber_id: subscriber.id,
        redirect: taxon_emails.first.redirect,
        utm_parameters: {}
      )
    end
  end

  def log_emails(emails)
    emails.each do |email|
      Rails.logger.info(<<-INFO.strip_heredoc)
        ----
        Created Email:
        id: #{email.id}
        subject: #{email.subject}
        body: #{email.body}
        subscriber_id: #{email.subscriber_id}
        ----
      INFO
    end
  end

  def log_non_taxon_lists(subscriber_lists)
    subscriber_lists.each do |list|
      Rails.logger.info(<<-INFO.strip_heredoc)
        ++++
        Not sending notification about non-Topic SubscriberList.
        id: #{list.id}
        title: #{list.title}
        links: #{list.links}
        tags: #{list.tags}
        ++++
      INFO
    end
  end

  def taxon_template
    <<~BODY
      Your subscription to email updates about '<%=subject%>' has ended because this topic no longer exists on GOV.UK.

      You might want to subscribe to updates about '<%=redirect.title%>' instead: [<%=redirect.url%>](<%=add_utm(redirect.url)%>)

      <%=presented_manage_subscriptions_links(address)%>
    BODY
  end

  def policy_and_policy_area_template
    <<~BODY
      We're changing the way content is organised on GOV.UK.

      Because of this, you will not get email updates about '<%= subject %>' anymore.

      If you want to continue receiving updates relating to this topic, you can [subscribe to the new '<%= redirect.title %>' page](<%= add_utm(redirect.url) %>).

      <%=presented_manage_subscriptions_links(address)%>
    BODY
  end
end
