class CreateDigestRuns < ActiveRecord::Migration[5.1]
  def change
    create_table :digest_runs do |t|
      t.date :date, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :range, null: false
      t.datetime :completed_at
      t.timestamps
    end
  end
end
