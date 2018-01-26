class Email < ApplicationRecord
  validates :address, :subject, :body, presence: true
end
