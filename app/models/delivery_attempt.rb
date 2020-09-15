class DeliveryAttempt < ApplicationRecord
  belongs_to :email

  enum status: { sent: 0, delivered: 1, undeliverable_failure: 3, provider_communication_failure: 4 }
  enum provider: { pseudo: 0, notify: 1, delay: 2 }

  def finished_sending_at
    sent_at || completed_at
  end
end
