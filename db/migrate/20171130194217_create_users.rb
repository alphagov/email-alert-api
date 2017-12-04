class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string   "name"
      t.string   "email"
      t.string   "uid"
      t.string   "organisation_slug"
      t.string   "organisation_content_id"
      t.string   "permissions", array: true, default: []
      t.boolean  "remotely_signed_out", default: false
      t.boolean  "disabled", default: false
    end
  end
end
