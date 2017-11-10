class MakeSubscriberAddressNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null :subscribers, :address, true
  end
end
