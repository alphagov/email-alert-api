module UTMHelpers
  def utm_params(content_change_id, frequency)
    "utm_source=#{content_change_id}&utm_medium=email&utm_campaign=govuk-notifications&utm_content=#{frequency}"
  end
end
