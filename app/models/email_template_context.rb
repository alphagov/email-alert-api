class EmailTemplateContext
  include ActionView::Helpers::TextHelper

  def initialize(data = {})
    data.each do |key, value|
      instance_variable_set("@#{key}", value)
      class_eval { attr_reader key }
    end
  end

  def fetch_binding
    binding
  end

  def add_utm(url, utm_parameters)
    uri = URI.parse(url)
    uri.query = [uri.query, *utm_parameters.map { |k| k.join("=") }].compact.join("&")
    uri.to_s
  end

  def presented_manage_subscriptions_links(subscriber)
    ManageSubscriptionsLinkPresenter.call(subscriber)
  end
end
