class EmailAlertCriteria
  attr_reader :content_item

  def initialize(content_item:)
    @content_item = content_item
  end

  def would_trigger_alert?
    return false unless base_path?
    return false unless title?
    return false unless public_updated_at?
    return false unless english?
    return false unless change_note?

    return false if blocked_publishing_app?
    return false if blocked_document_type?

    return false unless contains_supported_attribute? ||
      links_to_service_manual_service_standard? ||
      has_relevant_document_supertype?

    true
  end

  def base_path?
    content_item["base_path"].present?
  end

  def title?
    content_item["title"].present?
  end

  def public_updated_at?
    content_item["public_updated_at"].present?
  end

  def english?
    content_item["locale"].present? && content_item["locale"] == "en"
  end

  def change_note?
    history = content_item.dig("details", "change_history")
    return false if history.blank?

    change_note = history.max_by { |note| note["public_timestamp"] }
    change_note["note"].present?
  end

  def blocked_publishing_app?
    # Note this test is different to the one in email-alert-service,
    # here we only block collections-publisher, because we know that
    # travel-advice-publisher and specialist-publisher documents do
    # trigger emails, and here we don't need to worry about filtering
    # them out to avoid duplicates. We filter out collections-publisher
    # because it doesn't manage alertable content
    content_item["publishing_app"] == "collections-publisher"
  end

  def blocked_document_type?
    # These are documents that don't make sense to email someone about as they
    # are not useful to an end user (coming_soon, special_route), or the emails
    # are managed outside of email-alert-api (drug_safety_update)
    %w[coming_soon special_route drug_safety_update].include?(content_item["document_type"])
  end

  def contains_supported_attribute?
    supported_attributes = %w[
      policies
      service_manual_topics
      taxons
      world_locations
      topical_events
      people
      policy_areas
      roles
    ]

    keys = content_item.fetch("links", {}).keys + content_item.fetch("details", {}).keys
    (supported_attributes & keys).any?
  end

  def links_to_service_manual_service_standard?
    content_item.dig("links", "parent", 0, "content_id") == "00f693d4-866a-4fe6-a8d6-09cd7db8980b"
  end

  def has_relevant_document_supertype?
    return true unless ["other", "", nil].include?(content_item["government_document_supertype"])
    return true unless ["other", "", nil].include?(content_item["email_document_supertype"])

    false
  end
end
