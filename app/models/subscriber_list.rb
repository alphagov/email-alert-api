require 'json'

class SubscriberList < ActiveRecord::Base
  def self.with_at_least_one_tag_of_each_type(tags:)
    where("Array[:tag_keys] @> akeys(tags)", tag_keys: tags.keys).select do |list|
      list.tags.all? do |tag_type, tag_array|
        (tags[tag_type] & tag_array).count > 0
      end
    end
  end

  def tags
    @_tags ||= super.inject({}) do |hash, (tag_type, tags_json)|
      hash.merge(tag_type.to_sym => JSON.parse(tags_json))
    end
  end

  def subscription_url
    gov_delivery_config.fetch(:protocol) +
    "://" +
    gov_delivery_config.fetch(:public_hostname) +
    "/accounts/" +
    gov_delivery_config.fetch(:account_code) +
    "/subscriber/new?topic_id=" +
    self.gov_delivery_id
  end

  def to_json
    super(methods: :subscription_url)
  end

private

  def gov_delivery_config
    EmailAlertAPI.config.gov_delivery
  end
end
