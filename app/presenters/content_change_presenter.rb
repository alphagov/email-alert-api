class ContentChangePresenter
  EMAIL_DATE_FORMAT = "%I:%M %P on %-d %B %Y".freeze

  def initialize(content_change)
    @content_change = content_change
  end

  def self.call(content_change)
    new(content_change).call
  end

  def call
    <<~BODY
      [#{title}](#{content_url})

      #{change_note}: #{description}

      Updated at #{public_updated_at}
    BODY
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
end
