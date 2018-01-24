class ImmediateEmailBuilder
  def initialize(params:)
    @params = params
  end

  def subject
    "GOV.UK Update - #{title}"
  end

  def body
    <<~BODY
      [#{title}](#{content_url})

      #{change_note}: #{description}.

      Updated at #{public_updated_at}

      ----

      #{unsubscribe_links}
    BODY
  end

private

  attr_reader :params

  def title
    params.fetch(:title)
  end

  def base_path
    params.fetch(:base_path)
  end

  def change_note
    params.fetch(:change_note)
  end

  def description
    params.fetch(:description)
  end

  def public_updated_at
    params.fetch(:public_updated_at).strftime("%I:%M %P on %-d %B %Y")
  end

  def subscriber
    params.fetch(:subscriber)
  end

  def unsubscribe_links
    links = UnsubscribeLink.for(subscriber.subscriptions)
    links.map { |l| present_unsubscribe_link(l) }.join("\n\n")
  end

  def present_unsubscribe_link(link)
    "Unsubscribe from [#{link.title}](#{link.url})"
  end

  def content_url
    PublicUrlService.content_url(base_path: base_path)
  end
end
