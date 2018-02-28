class Subscription < ApplicationRecord
  belongs_to :subscriber
  belongs_to :subscriber_list

  has_many :subscription_contents

  enum frequency: { immediately: 0, daily: 1, weekly: 2 }
  enum source: { user_signed_up: 0, frequency_changed: 1, imported: 2 }

  before_validation :set_uuid

  validates :subscriber, uniqueness: { scope: :subscriber_list }

  scope :not_deleted, -> { where(deleted_at: nil) }

  def destroy
    update_attributes!(deleted_at: Time.now)
  end

private

  def set_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
