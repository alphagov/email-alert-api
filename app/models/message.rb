class Message < ApplicationRecord
  include SymbolizeJSON

  has_many :matched_messages
  has_many :subscription_contents

  validates_presence_of :title, :body
  validates :tags, tags: true
  validates :url, root_relative_url: true, allow_nil: true

  enum priority: { normal: 0, high: 1 }

  def mark_processed!
    update!(processed_at: Time.now)
  end

  def processed?
    processed_at.present?
  end
end
