class DataHygiene::TagChanger
  def initialize(from_topic_tag:, to_topic_tag:)
    @from_topic_tag = from_topic_tag
    @to_topic_tag = to_topic_tag
  end

  def update_records_tags
    commit_update unless to_topic_tag.blank?
  end

private

  attr_reader :from_topic_tag, :to_topic_tag

  def subscriber_records_with_tags
    SubscriberListQuery.new.at_least_one_topic_value_matches(from_topic_tag)
  end

  def commit_update
    subscriber_records_with_tags.each do |record|
      log "Duplicating SubscriberList id: #{record.id} replacing #{from_topic_tag} with #{to_topic_tag}"

      new_record = record.dup
      [:tags, :tags_json].each do |field|
        topics = record[field]["topics"]
        topics = JSON.parse(topics) if field == :tags

        topics.map! do |topic|
          topic == from_topic_tag ? to_topic_tag : topic
        end

        new_record[field]["topics"] = topics
        new_record[field]["topics"] = new_record[field]["topics"].to_json if field == :tags
      end
      new_record.save
    end
  end

  def log(message)
    puts message
  end
end
