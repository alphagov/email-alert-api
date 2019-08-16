class NotificationHandlerService
  def initialize(params:, user: nil)
    @params = params
    @user = user
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    content_change = ContentChange.create!(content_change_params)
    MetricsService.content_change_created
    MatchedContentChangeGenerationService.call(content_change: content_change)
    ProcessContentChangeWorker.perform_async(content_change.id)
  end

  private_class_method :new

private

  attr_reader :params, :user

  def content_change_params
    {
      content_id: params[:content_id],
      title: params[:title],
      change_note: params[:change_note],
      description: params[:description],
      base_path: params[:base_path],
      links: with_content_change_supertypes(params[:links]),
      tags: with_content_change_supertypes(params[:tags]),
      public_updated_at: Time.parse(params[:public_updated_at]),
      email_document_supertype: params[:email_document_supertype],
      government_document_supertype: params[:government_document_supertype],
      govuk_request_id: params[:govuk_request_id],
      document_type: params[:document_type],
      publishing_app: params[:publishing_app],
      priority: params.fetch(:priority, "normal").to_sym,
      signon_user_uid: user&.uid,
      footnote: params.fetch(:footnote, ""),
    }
  end

  def with_content_change_supertypes(hash)
    content_change_supertypes = GovukDocumentTypes.supertypes(document_type: params[:document_type])
    content_store_document_type = { content_store_document_type: params[:document_type] }
    content_change_supertypes.merge(hash).merge(content_store_document_type)
  end
end
