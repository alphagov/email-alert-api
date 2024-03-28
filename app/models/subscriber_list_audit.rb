class SubscriberListAudit < ApplicationRecord
  belongs_to :subscriber_list

  def self.increment_count(subscriber_list)
    record = SubscriberListAudit.find_or_create_by!(subscriber_list:)
    record.reference_count += 1
    record.save!
  end
end
