class BulkUnsubscribeListService
  include Callable

  attr_reader :subscriber_list, :params, :govuk_request_id, :user

  def initialize(subscriber_list:, params:, govuk_request_id:, user: nil)
    @subscriber_list = subscriber_list
    @params = params
    @govuk_request_id = govuk_request_id
    @user = user
  end

  def call
    message = Message.create!(message_params) if message_params
    Metrics.message_created if message
    BulkUnsubscribeListJob.perform_async(
      subscriber_list.id,
      message&.id,
    )
  end

  def message_params
    return unless params[:body]

    params
      .slice(:body, :sender_message_id)
      .merge(
        title: subscriber_list.title,
        criteria_rules: [{ id: subscriber_list.id }],
        govuk_request_id:,
        signon_user_uid: user&.uid,
        omit_footer_unsubscribe_link: true,
        override_subscription_frequency_to_immediate: true,
      )
  end
end
