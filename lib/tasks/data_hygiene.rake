desc "Delete subscriber lists without subscribers"
task delete_topics_without_subscribers: :environment do
  require "data_hygiene/delete_topics_without_subscribers"

  DataHygiene::DeleteTopicsWithoutSubscribers.new.call
  puts 'FINISHED'
end

desc "Create duplicate record for new tags"
task duplicate_record_for_tag: :environment do
  require "data_hygiene/tag_changer"

  from_topic_tag = ENV['FROM_TOPIC_TAG']
  to_topic_tag = ENV['TO_TOPIC_TAG']

  if from_topic_tag.blank?
    $stderr.puts "A from_topic_tag must be supplied"
    abort
  elsif to_topic_tag.blank?
    $stderr.puts "A to_topic_tag must be supplied"
    abort
  end

  puts 'STARTING'
  DataHygiene::TagChanger.new(from_topic_tag: from_topic_tag, to_topic_tag: to_topic_tag).update_records_tags
  puts 'FINISHED'
end

desc "Sync topic mappings to govdelivery, DO NOT USE IN PRODUCTION"
task sync_govdelivery_topic_mappings: :environment do
  unless ENV["ALLOW_GOVDELIVERY_SYNC"] == "allow"
    puts "Syncing GovDelivery has not been configured for this environment."
    puts "Running this against production GovDelivery would be a really bad idea."
    puts "If you're sure you want to run this, export ALLOW_GOVDELIVERY_SYNC='allow'"

    abort
  end

  unless EmailAlertAPI.config.gov_delivery[:hostname] == "stage-api.govdelivery.com"
    puts "It looks like you're running this sync with a non-staging GovDelivery configuration."
    puts "Running this against production GovDelivery would be a really bad idea."
    puts "If the GovDelivery staging hostname has changed, please update this application and try again."

    abort
  end

  production_account_code = "UKGOVUK"
  environment_account_code = EmailAlertAPI.config.gov_delivery[:account_code]

  unless environment_account_code == production_account_code
    puts "Updating topics in subscriber lists so that prefixes match account id for this environment..."

    SubscriberList.update_all(
      "gov_delivery_id = replace(gov_delivery_id, '#{production_account_code}_', '#{environment_account_code}_')"
    )

    puts "Done."
  end

  puts "Fetching topics.."
  topics = Services.gov_delivery.fetch_topics["topics"]
  topics = topics.map { |topic| [topic["name"], topic["code"]] }
  subscriber_lists = SubscriberList.where.not(gov_delivery_id: nil)
                                   .pluck(:title, :gov_delivery_id)
                                   .map { |title, gov_delivery_id| [(title || gov_delivery_id).strip, gov_delivery_id] }

  matching = topics & subscriber_lists
  to_be_deleted = topics - subscriber_lists
  to_be_created = subscriber_lists - topics

  if to_be_deleted.blank?
    puts "No topics to be deleted in GovDelivery."
  else
    puts "Deleting remote topics.."
    threads = to_be_deleted.each_slice(DataHygiene::BATCH_SIZE).map do |batch|
      Thread.new do
        batch.each do |name, code|
          puts "-- Deleting #{name} (#{code})"
          Services.gov_delivery.delete_topic(code)
        end
      end
    end
    threads.each(&:join)

    # GovDelivery delete topics asynchronously and/or are only eventually
    # consistent on deletes.  We have to wait until all the deletes take effect
    # or we'll get conflicts when trying to recreate them.
    puts 'Wainting for 30 seconds for topics to be asynchronously deleted'
    30.times do
      sleep 1
      print '.'
    end
  end

  3.times.each do |i|
    puts "Attempting to create subscriber lists: Attempt #{i}"
    to_be_created = DataHygiene.create_topics(to_be_created)
    return if to_be_created.empty?
    sleep 2
  end

  puts 'Failed to create all topics'
end

module DataHygiene
  # will hopefully limit delete runtime to 1 per sec * 300 / 60 =~ 5 minutes
  # a maximum thread count of 16000 / 300 =~ 54
  BATCH_SIZE = 300

  def self.create_topics(list)
    list.each do |gov_delivery_id, title|
      title = title || "MISSING TITLE #{gov_delivery_id}"
      puts "-- Creating #{title} (#{gov_delivery_id}) in GovDelivery"
      begin
        Services.gov_delivery.create_topic(title, gov_delivery_id)
      rescue TopicAlreadyExistsError
        retry_create << [gov_delivery_id, title]
        puts "-- Error Creating #{title} (#{gov_delivery_id}) in GovDelivery as delete has not completed"
      end
    end
    retry_create
  end
end
