class SubscriberList < ApplicationRecord
  include SymbolizeJSON
  include ActiveModel::Validations

  self.include_root_in_json = true

  validates :tags, tags: true
  validates :links, links: true
  validate :link_values_are_valid

  validates :title, presence: true
  validates :slug, uniqueness: true
  validates :url, root_relative_url: true, allow_nil: true
  validates :group_id, uuid: true, allow_nil: true

  has_many :subscriptions, dependent: :destroy
  has_many :subscribers, through: :subscriptions
  has_many :matched_content_changes
  has_many :matched_messages

  before_save do
    self.tags_digest = HashDigest.new(tags).generate
    self.links_digest = HashDigest.new(links).generate
  end

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

  scope :matching_criteria_rules, ->(criteria_rules) do
    SubscriberListsByCriteriaQuery.call(self, criteria_rules)
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
    options[:except] ||= %i[signon_user_uid]
    options[:methods] ||= %i[subscription_url gov_delivery_id active_subscriptions_count]
    super(options)
  end

  def is_travel_advice?
    self[:links].include?("countries")
  end

  def is_medical_safety_alert?
    self[:tags].fetch("format", []).include?("medical_safety_alert")
  end

private

  def link_values_are_valid
    unless valid_subscriber_criteria(:links)
      errors.add(:links, "All link values must be sent as Arrays")
    end
  end

  def valid_subscriber_criteria(link_or_tags)
    send(link_or_tags).values.all? do |hash|
      hash.all? do |operator, values|
        %i[all any].include?(operator) && values.is_a?(Array)
      end
    end
  end
end
