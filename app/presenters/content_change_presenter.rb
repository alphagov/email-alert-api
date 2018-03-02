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
      include_description? ? description_markdown : nil,
      change_note_markdown,
      include_mhra_line? ? mhra_line_markdown : nil,
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
    strip_markdown(description)
  end

  def change_note_markdown
    "#{public_updated_at}: #{strip_markdown(change_note)}"
  end

  def include_description?
    !content_change.is_travel_advice?
  end

  def include_mhra_line?
    content_change.is_medical_safety_alert?
  end

  def mhra_line_markdown
    "Do not reply to this email. To contact MHRA, email [email.support@mhra.gov.uk](mailto:email.support@mhra.gov.uk)"
  end
end
