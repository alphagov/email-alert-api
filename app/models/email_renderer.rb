class EmailRenderer
  def initialize(params:)
    @params = params
  end

  def subject
    "GOV.UK Update - #{title}"
  end

  def body
    <<~BODY
      #{change_note}: #{description}.

      #{url}
      Updated on #{public_updated_at}

      Unsubscribe from #{title} - #{unsubscribe_url}
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
    params.fetch(:public_updated_at).strftime("%I:%M %P, %-d %B %Y")
  end

  def url
    "#{website_root}#{base_path}"
  end

  def unsubscribe_url
    "#{website_root}/email/token/unsubscribe"
  end

  def website_root
    Plek.new.website_root
  end
end
