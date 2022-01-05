class UseTextForLongEmailsColumns < ActiveRecord::Migration[6.1]
  def up
    change_column :emails, :subject, :text
  end

  def down
    change_column :emails, :subject, :string
  end
end
