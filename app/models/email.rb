class Email < ApplicationRecord
  validates :address, :subject, :body, presence: true

  def self.create_from_params!(params)
    build_from_params(params).tap(&:save!)
  end

  def self.build_from_params(params)
    renderer = EmailRenderer.new(params: params)
    subscriber = params.fetch(:subscriber)

    new(
      address: subscriber.address,
      subject: renderer.subject,
      body: renderer.body
    )
  end
end
