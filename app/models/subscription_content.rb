class SubscriptionContent < ApplicationRecord
  belongs_to :subscription
  belongs_to :notification
  belongs_to :email, optional: true
end
