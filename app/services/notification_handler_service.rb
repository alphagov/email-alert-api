class NotificationHandlerService
  attr_reader :params
  def initialize(params:)
    @params = params
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    begin
      content_change = ContentChange.create!(content_change_params)
      increment_statsd
      SubscriptionContentWorker.perform_async(content_change_id: content_change.id, priority: priority)
    rescue StandardError => ex
      Raven.capture_exception(ex, tags: { version: 2 })
    end
  end

private

  def content_change_params
    {
      content_id: params[:content_id],
      title: params[:title],
      change_note: params[:change_note],
      description: params[:description],
      base_path: params[:base_path],
      links: params[:links],
      tags: params[:tags],
      public_updated_at: DateTime.parse(params[:public_updated_at]),
      email_document_supertype: params[:email_document_supertype],
      government_document_supertype: params[:government_document_supertype],
      govuk_request_id: params[:govuk_request_id],
      document_type: params[:document_type],
      publishing_app: params[:publishing_app],
    }
  end

  def priority
    params.fetch(:priority, "low").to_sym
  end

  def increment_statsd
    namespace = "#{Socket.gethostname}.content_changes_created"
    EmailAlertAPI.statsd.increment(namespace)
  end
end
