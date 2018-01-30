class Subscriber < ApplicationRecord
  with_options allow_nil: true do
    validates :address, format: { with: /@/, message: "is not an email address" }
    validates :address, uniqueness: true
  end

  has_many :subscriptions, dependent: :destroy
  has_many :subscriber_lists, through: :subscriptions
  has_many :digest_run_subscribers, dependent: :destroy
  has_many :digest_runs, through: :digest_run_subscribers

  def nullify_address!
    update!(address: nil)
  end
end
