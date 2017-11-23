class Email < ApplicationRecord
  validates :address, :subject, :body, presence: true

  def self.create_from_params!(params)
    build_from_params(params).tap(&:save!)
  end

  def self.build_from_params(params)
    renderer = EmailRenderer.new(params: params)

    new(
      address: params[:address],
      subject: renderer.subject,
      body: renderer.body
    )
  end

  def mark_processed!
    update_attribute(:processed_at, Time.now)
  end
end
