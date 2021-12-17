require "redcarpet/render_strip"

class ContentChangePresenter
  include Callable

  EMAIL_DATE_FORMAT = "%l:%M%P, %-d %B %Y".freeze

  def initialize(content_change, subscription)
    @content_change = content_change
    @subscription = subscription
  end

  def call
    [
      title_markdown,
      description_markdown,
      change_note_markdown.rstrip,
      footnote_markdown,
    ].compact.join("\n\n")
  end

private

  attr_reader :content_change, :subscription

  delegate :title, :description, :change_note, :footnote, to: :content_change

  def content_url
    PublicUrls.url_for(
      base_path: content_change.base_path,
      utm_source: content_change.id,
      utm_content: subscription.frequency,
      utm_campaign: subscription.subscriber_list.content_id.nil? ? "govuk-notifications-topic" : "govuk-notifications-single-page",
    )
  end

  def public_updated_at_header
    I18n.t!("emails.public_updated_at_header")
  end

  def public_updated_at
    content_change.public_updated_at.strftime(EMAIL_DATE_FORMAT).strip
  end

  def strip_markdown(string)
    markdown_stripper.render(string).gsub(/$\n/, "")
  end

  def markdown_stripper
    @markdown_stripper ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
  end

  def title_markdown
    "# [#{title}](#{content_url})"
  end

  def description_header
    I18n.t!("emails.description_header")
  end

  def description_markdown
    return nil if description.blank?

    "#{description_header}\n#{strip_markdown(description)}"
  end

  def change_note_header
    I18n.t!("emails.change_note_header")
  end

  def change_note_markdown
    <<~CHANGE_NOTE
      #{change_note_header}
      #{strip_markdown(change_note)}

      #{public_updated_at_header}
      #{public_updated_at}
    CHANGE_NOTE
  end

  def footnote_markdown
    return nil if footnote.blank?

    strip_markdown(footnote)
  end
end
