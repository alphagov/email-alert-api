class Subscription < ApplicationRecord
  belongs_to :subscriber
  belongs_to :subscriber_list

  validates :subscriber, uniqueness: { scope: :subscriber_list }
end
