module UTMHelpers
  def utm_params(content_change_id, frequency)
    "utm_source=#{content_change_id}&utm_medium=email&utm_campaign=govuk-notifications&utm_content=#{frequency}"
  end

  def message_utm_params(message_id, frequency)
    "utm_campaign=govuk-notifications-message&utm_content=#{frequency}&utm_medium=email&utm_source=#{message_id}"
  end
end
