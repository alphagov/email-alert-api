module TopicHelpers
  def create_topic(params)
    bare_app.create_topic(
      null_context(
        params: params
      )
    )
  end
end
