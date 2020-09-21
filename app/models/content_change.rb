class ContentChange < ApplicationRecord
  include SymbolizeJSON

  validates :content_id,
            :title,
            :base_path,
            :change_note,
            :public_updated_at,
            :email_document_supertype,
            :government_document_supertype,
            :govuk_request_id,
            :document_type,
            :publishing_app,
            presence: true

  has_many :matched_content_changes
  has_many :subscription_contents

  enum priority: { normal: 0, high: 1 }

  def queue
    priority == "high" ? :delivery_immediate_high : :delivery_immediate
  end
end
