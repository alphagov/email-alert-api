class MessagePresenter < ApplicationPresenter
  def initialize(message, frequency: "immediate")
    @message = message
    @frequency = frequency
  end

  def call
    [
      title_markdown,
      body,
    ].compact.join("\n\n") + "\n"
  end

private

  attr_reader :message, :frequency

  delegate :title, :body, :url, to: :message

  def absolute_url
    return unless url

    parsed = URI.join(Plek.new.website_root, url)
    add_ga_query_params(parsed)

    parsed.to_s
  rescue URI::InvalidURIError
    nil
  end

  def add_ga_query_params(uri)
    return unless uri.to_s.start_with?(Plek.new.website_root)

    query_params = Rack::Utils.parse_nested_query(uri.query)

    return if query_params.keys.any? { |k| k.match(/\Autm/) }

    query = {
      utm_source: message.id,
      utm_medium: "email",
      utm_campaign: "govuk-notifications-message",
      utm_content: frequency,
    }.to_query

    if uri.query
      uri.query += "&#{query}"
    else
      uri.query = query
    end
  end

  def title_markdown
    return title unless (destination = absolute_url)

    "[#{title}](#{destination})"
  end
end
