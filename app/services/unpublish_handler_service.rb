class UnpublishHandlerService
  def self.call(*args)
    new.call(*args)
  end

  def call(content_id, redirect)
    subscriber_lists = fetch_subscriber_lists(content_id)
    type = find_type(subscriber_lists, content_id)
    case type
    when :taxon_tree
      unsubscribe_taxon(subscriber_lists, redirect)
    else
      unsubscribe_other(subscriber_lists)
    end
  end

private


  def unsubscribe_other(subscriber_lists)
    log_non_taxon_lists(subscriber_lists)
  end

  def unsubscribe_taxon(subscriber_lists, redirect)
    email_parameters = build_emails(subscriber_lists, redirect)
    all_email_parameters = email_parameters + courtesy_emails(email_parameters)

    emails = UnpublishEmailBuilder.call(all_email_parameters)
    queue_delivery_request_workers(emails)
    log_taxon_emails(emails)
    unsubscribe(subscriber_lists)
  end

  def unsubscribe(subscriber_lists)
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
    SubscriberList
      .where(":id IN (SELECT json_array_elements((json_each(links)).value)::text)", id: "\"#{content_id}\"")
      .includes(:subscribers)
  end

  def build_emails(subscriber_lists, redirect)
    subscriber_lists.flat_map do |subscriber_list|
      subscriber_list.subscribers.activated.map do |subscriber|
        {
          subject: subscriber_list.title,
          address: subscriber.address,
          subscriber_id: subscriber.id,
          redirect: redirect,
          utm_parameters: {
              'utm_source' => subscriber_list.title,
              'utm_medium' => 'email',
              'utm_campaign' => 'govuk-notification'
          }
        }
      end
    end
  end

  def courtesy_emails(taxon_emails)
    return [] if taxon_emails.empty?
    Subscriber.where(address: Email::COURTESY_EMAIL).map do |subscriber|
      {
        subject: taxon_emails.first.fetch(:subject),
        address: subscriber.address,
        subscriber_id: subscriber.id,
        redirect: taxon_emails.first.fetch(:redirect),
        utm_parameters: {}
      }
    end
  end

  def log_taxon_emails(emails)
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
end
