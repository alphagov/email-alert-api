class UnpublishHandlerService
  def self.call(*args)
    new.call(*args)
  end

  def call(content_id, redirect)
    lists = subscriber_list(content_id)
    taxon_subscriber_lists, other_subscriber_lists = split_subscriber_lists(lists)

    taxon_email_parameters = build_emails(taxon_subscriber_lists)
    all_email_parameters = taxon_email_parameters + courtesy_emails(taxon_email_parameters)
    emails = UnpublishEmailBuilder.call(all_email_parameters, redirect)

    queue_delivery_request_workers(emails)

    log_taxon_emails(emails)
    log_non_taxon_lists(other_subscriber_lists)

    unsubscribe(taxon_subscriber_lists)
  end

private

  def split_subscriber_lists(lists)
    list_groupings = lists.group_by do |list|
      list.links.has_key?(:taxon_tree) ? :taxon : :other
    end

    [list_groupings.fetch(:taxon, []), list_groupings.fetch(:other, [])]
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

  # For this query to return the content id has to be wrapped in a double quote blame psql 9.3
  def subscriber_list(content_id)
    SubscriberList
      .where(":id IN (SELECT json_array_elements((json_each(links)).value)::text)", id: "\"#{content_id}\"")
      .includes(:subscribers)
  end

  def build_emails(subscriber_lists)
    subscriber_lists.flat_map do |subscriber_list|
      subscriber_list.subscribers.activated.map do |subscriber|
        {
          subject: subscriber_list.title,
          address: subscriber.address,
          subscriber_id: subscriber.id
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
        subscriber_id: subscriber.id
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
