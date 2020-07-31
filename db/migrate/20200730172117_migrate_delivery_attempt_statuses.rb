class MigrateDeliveryAttemptStatuses < ActiveRecord::Migration[6.0]
  class DeliveryAttempt < ApplicationRecord; end

  def up
    # we've changed from an enum of:
    #  enum status: { sending: 0, delivered: 1, permanent_failure: 2, temporary_failure: 3, technical_failure: 4, internal_failure: 5 }
    #
    # to:
    #   enum status: { sending: 0, delivered: 1, undeliverable_failure: 3, provider_communication_failure: 4 }
    #
    # This updates all records that fall outside these parameters
    DeliveryAttempt.where(status: 2).update_all(status: 3)
    DeliveryAttempt.where(status: 5).update_all(status: 4)
  end
end
