class ContentChange < ApplicationRecord
  include SymbolizeJSON

  enum priority: %i(low high)

  def mark_processed!
    update!(processed_at: Time.now)
  end
end
