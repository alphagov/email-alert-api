class Subscriber < ActiveRecord::Base
  validates :address, presence: true
  validates_format_of :address, with: /@/, message: "is not an email address"
end
