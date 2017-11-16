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
      content_change = ContentChange.create!(notification_params)
      deliver_to_subscribers(content_change)
      deliver_to_courtesy_subscribers(content_change)
    rescue StandardError => ex
      Raven.capture_exception(ex, tags: { version: 2 })
    end
  end

private

  def create_email(content_change, subscriber)
    Email.create_from_params!(email_params.merge(address: subscriber.address))
  end

  def deliver_to_subscribers(content_change)
    subscribers_for(content_change: content_change).find_each do |subscriber|
      email = create_email(content_change, subscriber)
      DeliverEmailWorker.perform_async_with_priority(
        email.id, priority: priority
      )
    end
  end

  def deliver_to_courtesy_subscribers(content_change)
    addresses = [
      "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk",
    ]

    Subscriber.where(address: addresses).find_each do |subscriber|
      email = create_email(content_change, subscriber)
      DeliverEmailWorker.perform_async_with_priority(
        email.id, priority: priority
      )
    end
  end

  def subscribers_for(content_change:)
    Subscriber.joins(:subscriptions).where(
      subscriptions: {
        subscriber_list: subscriber_lists_for(content_change: content_change)
      }
    ).distinct
  end

  def subscriber_lists_for(content_change:)
    SubscriberListQuery.new(
      tags: content_change.tags,
      links: content_change.links,
      document_type: content_change.document_type,
      email_document_supertype: content_change.email_document_supertype,
      government_document_supertype: content_change.government_document_supertype,
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
      public_updated_at: DateTime.parse(params[:public_updated_at]),
    }
  end

  def priority
    params.fetch(:priority, "low").to_sym
  end
end
