class ContentChange < ApplicationRecord
  include SymbolizeJSON

  validates_presence_of :content_id, :title, :base_path, :change_note, :description,
    :public_updated_at, :email_document_supertype, :government_document_supertype,
    :govuk_request_id, :document_type, :publishing_app

  has_many :matched_content_changes

  enum priority: { normal: 0, high: 1 }

  def mark_processed!
    update!(processed_at: Time.now)
  end
end
