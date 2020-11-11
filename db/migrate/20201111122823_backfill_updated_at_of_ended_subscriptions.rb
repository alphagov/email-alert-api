class BackfillUpdatedAtOfEndedSubscriptions < ActiveRecord::Migration[6.0]
  class Subscription < ApplicationRecord; end

  disable_ddl_transaction!

  def change
    ended_subscriptions = Subscription.where("ended_at > updated_at")

    ended_subscriptions.find_each do |sub|
      sub.update!(updated_at: sub.ended_at)
    end
  end
end
