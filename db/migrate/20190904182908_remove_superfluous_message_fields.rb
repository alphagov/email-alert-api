class RemoveSuperfluousMessageFields < ActiveRecord::Migration[5.2]
  def change
    change_table :messages, bulk: true do |t|
      t.remove :links,
               :tags,
               :document_type,
               :email_document_supertype,
               :government_document_supertype
    end
  end
end
