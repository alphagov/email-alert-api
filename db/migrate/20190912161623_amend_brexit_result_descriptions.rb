class AmendBrexitResultDescriptions < ActiveRecord::Migration[5.2]
  def up
    SubscriberList.connection.execute("
      UPDATE subscriber_lists
      SET description = REGEXP_REPLACE(
        description,
        '\\[.*\\]\\((.*)\\).*',
        '[You can view a copy of your results on GOV.UK.](\\1)'
      )
      WHERE description like '%You can view a copy of your Brexit tool results%'
    ")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
