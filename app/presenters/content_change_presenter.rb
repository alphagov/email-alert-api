require 'redcarpet/render_strip'

class ContentChangePresenter
  EMAIL_DATE_FORMAT = "%l:%M%P, %-d %B %Y".freeze

  def initialize(content_change)
    @content_change = content_change
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    [
      title_markdown,
      description_markdown,
      change_note_markdown,
    ].compact.join("\n\n") + "\n"
  end

  private_class_method :new

private

  attr_reader :content_change

  delegate :title, :description, :change_note, to: :content_change

  def content_url
    PublicUrlService.url_for(base_path: content_change.base_path)
  end

  def public_updated_at
    content_change.public_updated_at.strftime(EMAIL_DATE_FORMAT)
  end

  def strip_markdown(string)
    markdown_stripper.render(string).gsub(/$\n/, "")
  end

  def markdown_stripper
    @markdown_stripper ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
  end

  def title_markdown
    "[#{title}](#{content_url})"
  end

  def description_markdown
    return nil if description.blank?
    strip_markdown(description)
  end

  def change_note_markdown
    "#{public_updated_at}: #{strip_markdown(change_note)}"
  end
end
