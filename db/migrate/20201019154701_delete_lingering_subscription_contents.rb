class DeleteLingeringSubscriptionContents < ActiveRecord::Migration[6.0]
  class SubscriptionContent < ApplicationRecord; end

  def up
    SubscriptionContent.where("created_at < '2020-06-23'").delete_all
  end
end
