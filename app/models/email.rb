class Email < ApplicationRecord
  belongs_to :notification
  validates :subject, :body, :notification, presence: true

  def self.create_from_params!(params)
    build_from_params(params).tap(&:save!)
  end

  def self.build_from_params(params)
    new.tap do |instance|
      instance.notification_id = params[:notification_id]
      instance.subject = params[:title]
      instance.body = <<~BODY
        description: #{params[:description]}
        change_note: #{params[:change_note]}
        base_path: #{params[:base_path]}
        updated: #{instance.format_date(params[:public_updated_at])}
      BODY
    end
  end

  def format_date(date)
    return unless date
    date.strftime("%H:%M %-d %B %Y")
  end
end
