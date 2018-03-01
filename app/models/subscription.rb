class Subscription < ApplicationRecord
  belongs_to :subscriber
  belongs_to :subscriber_list

  has_many :subscription_contents

  enum frequency: { immediately: 0, daily: 1, weekly: 2 }
  enum source: { user_signed_up: 0, frequency_changed: 1, imported: 2 }, _prefix: true

  validates :subscriber, uniqueness: { scope: :subscriber_list }

  scope :active, -> { where(ended_at: nil) }

  def destroy
    update_attributes!(ended_at: Time.now)
  end
end
