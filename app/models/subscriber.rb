class Subscriber < ApplicationRecord
  with_options allow_nil: true do
    validates_with EmailAddressValidator, fields: [:address]
    validates_uniqueness_of :address, case_sensitive: false
  end

  has_many :subscriptions, -> { not_deleted }
  has_many :subscriber_lists, through: :subscriptions
  has_many :digest_run_subscribers, dependent: :destroy
  has_many :digest_runs, through: :digest_run_subscribers

  def nullify_address!
    update!(address: nil)
  end
end
