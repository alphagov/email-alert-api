class NotificationHandler
  attr_reader :params
  def initialize(params:)
    @params = params
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    begin
      notification = Notification.create!(notification_params)
      deliver_to_subscribers(notification)
      deliver_to_courtesy_subscribers(notification)
    rescue StandardError => ex
      Raven.capture_exception(ex, tags: { version: 2 })
    end
  end

private

  def create_email(notification, subscriber)
    Email.create_from_params!(
      email_params.merge(notification_id: notification.id, address: subscriber.address)
    )
  end

  def deliver_to_subscribers(notification)
    subscribers_for(notification: notification).find_each do |subscriber|
      email = create_email(notification, subscriber)
      DeliverToSubscriberWorker.perform_async_with_priority(
        email.id, priority: priority
      )
    end
  end

  def deliver_to_courtesy_subscribers(notification)
    addresses = [
      "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk",
    ]

    Subscriber.where(address: addresses).find_each do |subscriber|
      email = create_email(notification, subscriber)
      DeliverToSubscriberWorker.perform_async_with_priority(
        email.id, priority: priority
      )
    end
  end

  def subscribers_for(notification:)
    Subscriber.joins(:subscriptions).where(
      subscriptions: {
        subscriber_list: subscriber_lists_for(notification: notification)
      }
    ).distinct
  end

  def subscriber_lists_for(notification:)
    SubscriberListQuery.new(
      tags: notification.tags,
      links: notification.links,
      document_type: notification.document_type,
      email_document_supertype: notification.email_document_supertype,
      government_document_supertype: notification.government_document_supertype,
    ).lists
  end

  def notification_params
    {
      content_id: params[:content_id],
      title: params[:title],
      change_note: params[:change_note],
      description: params[:description],
      base_path: params[:base_path],
      links: params[:links],
      tags: params[:tags],
      public_updated_at: params[:public_updated_at],
      email_document_supertype: params[:email_document_supertype],
      government_document_supertype: params[:government_document_supertype],
      govuk_request_id: params[:govuk_request_id],
      document_type: params[:document_type],
      publishing_app: params[:publishing_app],
    }
  end

  def email_params
    {
      title: params[:title],
      change_note: params[:change_note],
      description: params[:description],
      base_path: params[:base_path],
    }
  end

  def priority
    params.fetch(:priority, "low").to_sym
  end
end
