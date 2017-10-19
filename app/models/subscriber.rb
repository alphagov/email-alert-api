class Subscriber < ActiveRecord::Base
  validates :address, presence: true
  validates :address, format: { with: /@/, message: "is not an email address" }
  validates :address, uniqueness: true
end
