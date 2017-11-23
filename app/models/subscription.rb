class Subscription < ApplicationRecord
  belongs_to :subscriber
  belongs_to :subscriber_list

  before_validation :set_uuid

  validates :subscriber, uniqueness: { scope: :subscriber_list }

private

  def set_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
