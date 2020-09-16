class DeliveryAttempt < ApplicationRecord
  self.ignored_columns = %w[sent_at completed_at]

  belongs_to :email

  enum status: { sent: 0, delivered: 1, undeliverable_failure: 3, provider_communication_failure: 4 }
  enum provider: { pseudo: 0, notify: 1, delay: 2 }
end
