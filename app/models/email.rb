class Email < ApplicationRecord
  validates :address, :subject, :body, presence: true

  def self.create_from_params!(params)
    new_from_params(params).tap(&:save!)
  end

  def self.new_from_params(params)
    new(build_from_params(params))
  end

  def self.build_from_params(params)
    builder = ImmediateEmailBuilder.new(params: params)
    subscriber = params.fetch(:subscriber)

    {
      address: subscriber.address,
      subject: builder.subject,
      body: builder.body
    }
  end
end
