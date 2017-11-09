class EmailRenderer
  def initialize(params:)
    @params = params
  end

  def subject
    params[:title]
  end

  def body
    <<~BODY
      There has been a change to *#{params[:title]}* on #{format_date(params[:public_updated_at])}.

      > #{params[:description]}

      **#{params[:change_note]}**
    BODY
  end

private

  attr_reader :params

  def format_date(date)
    return unless date
    date.strftime("%H:%M %-d %B %Y")
  end
end
