class Message < ApplicationRecord
  include SymbolizeJSON

  has_many :matched_messages
  has_many :subscription_contents

  validates :title, :body, :criteria_rules, :govuk_request_id, presence: true
  validates :criteria_rules, criteria_schema: true, allow_blank: true
  validates :sender_message_id, uuid: true, uniqueness: true, allow_nil: true

  enum :priority, { normal: 0, high: 1 }

  def queue
    :send_email_immediate
  end
end
