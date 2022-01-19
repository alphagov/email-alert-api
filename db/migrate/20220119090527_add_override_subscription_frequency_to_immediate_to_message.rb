class AddOverrideSubscriptionFrequencyToImmediateToMessage < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :override_subscription_frequency_to_immediate, :boolean, default: false, null: false
  end
end
