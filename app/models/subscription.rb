class Subscription < ApplicationRecord
  belongs_to :subscriber
  belongs_to :subscriber_list
end
