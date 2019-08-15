class Message < ApplicationRecord
  include SymbolizeJSON

  has_many :matched_messages

  validates_presence_of :title, :body
  validates :path, absolute_path: true, allow_nil: true

  enum priority: { normal: 0, high: 1 }

  def mark_processed!
    update!(processed_at: Time.now)
  end

  def processed?
    processed_at.present?
  end
end
