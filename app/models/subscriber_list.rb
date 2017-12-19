class SubscriberList < ApplicationRecord
  include SymbolizeJSON

  self.include_root_in_json = true

  validate :tag_values_are_valid
  validate :link_values_are_valid

  validates :title, presence: true

  has_many :subscriptions
  has_many :subscribers, through: :subscriptions

  def self.build_from(params:, gov_delivery_id:)
    new(
      title: params[:title],
      tags:  params[:tags],
      links: params[:links],
      document_type: params[:document_type],
      email_document_supertype: params[:email_document_supertype],
      government_document_supertype: params[:government_document_supertype],
      gov_delivery_id: gov_delivery_id,
    )
  end

  def subscription_url
    if use_email_alert_frontend_for_email_collection?
      PublicUrlService.subscription_url(gov_delivery_id: gov_delivery_id)
    else
      PublicUrlService.deprecated_subscription_url(gov_delivery_id: gov_delivery_id)
    end
  end

  def to_json
    super(methods: :subscription_url)
  end

private

  def tag_values_are_valid
    unless self[:tags].all? { |_, v| v.is_a?(Array) }
      self.errors.add(:tags, "All tag values must be sent as Arrays")
    end
  end

  def link_values_are_valid
    unless self[:links].all? { |_, v| v.is_a?(Array) }
      self.errors.add(:links, "All link values must be sent as Arrays")
    end
  end

  def gov_delivery_config
    EmailAlertAPI.config.gov_delivery
  end

  # We could make this more sophisticated if needed, e.g. check document_type.
  def use_email_alert_frontend_for_email_collection?
    ENV.include?("USE_EMAIL_ALERT_FRONTEND_FOR_EMAIL_COLLECTION")
  end
end
