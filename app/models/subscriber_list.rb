class SubscriberList < ApplicationRecord
  include SymbolizeJSON

  self.include_root_in_json = true

  validate :tag_values_are_valid
  validate :link_values_are_valid
  validate :content_purpose_supergroup_is_valid

  validates :title, presence: true
  validates_uniqueness_of :slug

  has_many :subscriptions
  has_many :subscribers, through: :subscriptions
  has_many :matched_content_changes

  scope :find_by_links_value, ->(content_id) do
      # For this query to return the content id has to be wrapped in a
      # double quote blame psql 9.
    sql = <<~SQLSTRING
      :id IN (
           SELECT json_array_elements(
            CASE
              WHEN ((link_table.link#>'{any}') IS NOT NULL) THEN link_table.link->'any'
              WHEN ((link_table.link#>'{all}') IS NOT NULL) THEN link_table.link->'all'
              ELSE link_table.link
            END)::text AS content_id FROM (SELECT ((json_each(links)).value)::json AS link) AS link_table
      )
    SQLSTRING
    where(sql, id: "\"#{content_id}\"")
  end

  def subscription_url
    PublicUrlService.subscription_url(slug: slug)
  end

  def gov_delivery_id
    slug
  end

  def active_subscriptions_count
    subscriptions.active.count
  end

  def to_json(options = {})
    options[:except] ||= %i{signon_user_uid}
    options[:methods] ||= %i{subscription_url gov_delivery_id active_subscriptions_count}
    super(options)
  end

  def is_travel_advice?
    self[:links].include?("countries")
  end

  def is_medical_safety_alert?
    self[:tags].fetch("format", []).include?("medical_safety_alert")
  end

private

  def tag_values_are_valid
    unless valid_subscriber_criteria(:tags)
      self.errors.add(:tags, "All tag values must be sent as Arrays")
    end
  end

  def link_values_are_valid
    unless valid_subscriber_criteria(:links)
      self.errors.add(:links, "All link values must be sent as Arrays")
    end
  end

  def supergroup_document_types(supergroup)
    GovukDocumentTypes.supergroup_document_types supergroup
  end

  def content_purpose_supergroup_is_valid
    valid = content_purpose_supergroup.nil? || supergroup_document_types(content_purpose_supergroup).any?

    unless valid
      self.errors.add(:content_purpose_supergroup, "Invalid supergroup '#{content_purpose_supergroup}'")
    end
  end

  def valid_subscriber_criteria(link_or_tags)
    self.send(link_or_tags).values.all? do |hash|
      hash.all? do |operator, values|
        %i[all any].include?(operator) && values.is_a?(Array)
      end
    end
  end
end
