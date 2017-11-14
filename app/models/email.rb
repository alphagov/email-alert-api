class Email < ApplicationRecord
  belongs_to :content_change

  validates :address, :subject, :body, :content_change, presence: true

  def self.create_from_params!(params)
    build_from_params(params).tap(&:save!)
  end

  def self.build_from_params(params)
    renderer = EmailRenderer.new(params: params)

    new(
      content_change_id: params[:content_change_id],
      address: params[:address],
      subject: renderer.subject,
      body: renderer.body
    )
  end
end
