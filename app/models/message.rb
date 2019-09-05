class Message < ApplicationRecord
  include SymbolizeJSON

  has_many :matched_messages
  has_many :subscription_contents

  validates_presence_of :title, :body, :criteria_rules, :govuk_request_id
  validates :url, root_relative_url: true, allow_nil: true
  validates :criteria_rules, criteria_schema: true
  validates :sender_message_id,
            format: {
              with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\Z/i,
              message: "is not a UUID"
            },
            uniqueness: true,
            allow_nil: true

  enum priority: { normal: 0, high: 1 }

  def mark_processed!
    update!(processed_at: Time.now)
  end

  def processed?
    processed_at.present?
  end
end
