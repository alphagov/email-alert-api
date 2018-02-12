class Email < ApplicationRecord
  has_many :delivery_attempts

  validates :address, :subject, :body, presence: true
end
