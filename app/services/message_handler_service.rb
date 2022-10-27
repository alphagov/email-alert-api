class MessageHandlerService
  include Callable

  def initialize(params:, govuk_request_id:, user: nil)
    @params = params
    @govuk_request_id = govuk_request_id
    @user = user
  end

  def call
    message = Message.create!(message_params)
    Metrics.message_created
    ProcessMessageWorker.perform_async(message.id)
  end

private

  attr_reader :params, :govuk_request_id, :user

  def message_params
    params
      .slice(:title, :body, :sender_message_id)
      .merge(
        criteria_rules: params[:criteria_rules].presence,
        priority: params.fetch(:priority, "normal"),
        govuk_request_id:,
        signon_user_uid: user&.uid,
        id: params[:sender_message_id],
      )
  end
end
