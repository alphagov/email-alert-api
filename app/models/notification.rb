require_relative "extensions/symbolize_json"

class Notification < ApplicationRecord
  include SymbolizeJSON

  def self.build_from(params:)
    new(
      content_id: params[:content_id],
      title: params[:title],
      change_note: params[:change_note],
      description: params[:description],
      links: params[:links],
      tags: params[:tags],
      public_updated_at: params[:public_updated_at],
      email_document_supertype: params[:email_document_supertype],
      government_document_supertype: params[:government_document_supertype],
      govuk_request_id: params[:govuk_request_id],
      document_type: params[:document_type],
      publishing_app: params[:publishing_app],
    )
  end
end
