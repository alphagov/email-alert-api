class MessageHandlerService
  def initialize(params:, govuk_request_id:, user: nil)
    @params = params
    @govuk_request_id = govuk_request_id
    @user = user
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    message = Message.create!(message_params)
    MetricsService.message_created
    MatchedMessageGenerationService.call(message: message)
    ProcessMessageWorker.perform_async(message.id)
  end

  private_class_method :new

private

  attr_reader :params, :govuk_request_id, :user

  def message_params
    params
      .slice(:title, :url, :body, :sender_message_id)
      .merge(criteria_rules: params[:criteria_rules].presence,
             links: with_supertypes(params.fetch(:links, {})),
             tags: with_supertypes(params.fetch(:tags, {})),
             document_type: params[:document_type].presence,
             email_document_supertype: params[:email_document_supertype].presence,
             government_document_supertype: params[:government_document_supertype].presence,
             priority: params.fetch(:priority, "normal"),
             govuk_request_id: govuk_request_id,
             signon_user_uid: user&.uid)
  end

  def with_supertypes(hash)
    return hash unless params[:document_type].present?

    supertypes = GovukDocumentTypes.supertypes(document_type: params[:document_type])
    content_store_document_type = { content_store_document_type: params[:document_type] }
    supertypes.merge(hash).merge(content_store_document_type)
  end
end
