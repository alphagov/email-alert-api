module EmailBuilderHelper
  def subject(content_change = nil)
    I18n.t("frequencies.#{frequency}.subject", title: content_change&.title)
  end

  def permission_reminder(*subscription_title)
    title = I18n.t("frequencies.#{frequency}.permission_reminder_topic", :missing, default: "", title: subscription_title.first)
    I18n.t("permission_reminder", title: title)
  end

  def feedback_link
    survey_link = I18n.t("frequencies.#{frequency}.survey_link")
    I18n.t("feedback_link", survey_link: survey_link, feedback_link: "#{Plek.new.website_root}/contact")
  end

  def frequency
    defined?(digest_run).nil? ? "immediately" : digest_run.range
  end
end
