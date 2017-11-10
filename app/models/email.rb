class Email < ApplicationRecord
  belongs_to :notification

  validates :address, :subject, :body, :notification, presence: true

  def self.create_from_params!(params)
    build_from_params(params).tap(&:save!)
  end

  def self.build_from_params(params)
    renderer = EmailRenderer.new(params: params)

    new(
      notification_id: params[:notification_id],
      address: params[:address],
      subject: renderer.subject,
      body: renderer.body
    )
  end
end
