class ContentChange < ApplicationRecord
  include SymbolizeJSON

  has_many :matched_content_changes

  enum priority: { normal: 0, high: 1 }

  def mark_processed!
    update!(processed_at: Time.now)
  end

  def is_travel_advice?
    links.include?(:countries)
  end

  def is_medical_safety_alert?
    tags.fetch(:format, []).include?("medical_safety_alert")
  end
end
