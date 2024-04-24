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

  has_many :subscriptions, dependent: :destroy
  has_many :subscribers, through: :subscriptions
  has_many :matched_content_changes
  has_many :matched_messages

  before_save do
    self.tags_digest = HashDigest.new(tags).generate
    self.links_digest = HashDigest.new(links).generate
  end

  scope :matching_criteria_rules,
        lambda { |criteria_rules|
          SubscriberListsByCriteriaQuery.call(self, criteria_rules)
        }

  def active_subscriptions_count
    subscriptions.active.count
  end

  def to_json(options = {})
    options[:except] ||= %i[signon_user_uid]
    options[:methods] ||= %i[active_subscriptions_count]
    super(options)
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
