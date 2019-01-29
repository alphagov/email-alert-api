class ContentChange < ApplicationRecord
  include SymbolizeJSON

  validates_presence_of :content_id, :title, :base_path, :change_note,
    :public_updated_at, :email_document_supertype, :government_document_supertype,
    :govuk_request_id, :document_type, :publishing_app

  has_many :matched_content_changes
  has_many :subscription_contents

  enum priority: { normal: 0, high: 1 }

  def mark_processed!
    update!(processed_at: Time.now)
  end

  def processed?
    processed_at.present?
  end

  def content_purpose_supergroup
    @content_purpose_supergroup ||= begin
      group = GovukDocumentTypes.supertypes(document_type: document_type)['content_purpose_supergroup']
      group == 'other' ? nil : group
    end
  end
end
