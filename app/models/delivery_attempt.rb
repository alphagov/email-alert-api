class DeliveryAttempt < ApplicationRecord
  belongs_to :email

  enum status: { sending: 0, delivered: 1, permanent_failure: 2, temporary_failure: 3, technical_failure: 4, internal_failure: 5 }
  enum provider: { pseudo: 0, notify: 1, delay: 2 }

  def finished_sending_at
    sent_at || completed_at
  end
end
