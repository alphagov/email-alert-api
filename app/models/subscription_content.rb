class SubscriptionContent < ApplicationRecord
  belongs_to :subscription
  belongs_to :content_change
  belongs_to :email, optional: true
end
