class Subscriber < ActiveRecord::Base
  validates :address, presence: true
  validates :address, format: { with: /@/, message: "is not an email address" }
  validates :address, uniqueness: true

  has_many :subscriptions, dependent: :destroy
  has_many :subscriber_lists, through: :subscriptions
end
