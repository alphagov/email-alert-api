module SubscriberListHelpers
  def create_subscriber_list(params)
    bare_app.create_subscriber_list(
      null_context(
        params: params
      )
    )
  end
end
