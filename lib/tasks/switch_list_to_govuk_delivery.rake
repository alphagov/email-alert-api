desc "Switch a subscriber list to govuk-delivery from email-alert-api"
task switch_list_to_govuk_delivery: [:environment] do |_, args|
  TICK = "\e[32m✓\e[0m"
  CROSS = "\e[31m✗\e[0m"

  args.extras.each do |gov_delivery_id|
    # Enable the list in govuk-delivery
    response = Services.govuk_delivery.enable_list(gov_delivery_id).to_hash

    if response['enabled'].nil? || response['enabled']
      puts "#{TICK} #{gov_delivery_id} has been enabled in govuk-delivery"
    else
      puts "#{CROSS} #{gov_delivery_id} could not be enabled in govuk-delivery"

      # We don't want to disable the list in email-alert-api if we couldn't
      # successfully enable it in govuk-delivery
      exit
    end

    # Disable the list in email-alert-api
    subscriber_list = SubscriberList.where(gov_delivery_id: gov_delivery_id).first
    subscriber_list.enabled = false

    if subscriber_list.save
      puts "#{TICK} #{gov_delivery_id} has been disabled in email-alert-api"
    else
      puts "#{CROSS} #{gov_delivery_id} could not be disabled in email-alert-api - disabling in govuk-delivery"

      # Disable the list in govuk-delivery to keep consistency
      Services.govuk_delivery.disable_list(gov_delivery_id)
    end
  end
end

desc "Switch all subscriber lists to govuk-delivery from email-alert-api"
task switch_all_lists_to_govuk_delivery: :environment do
  SubscriberList.where(migrated_from_gov_uk_delivery: true).find_each do |list|
    begin
      Services.govuk_delivery.enable_list(list.gov_delivery_id)

      list.enabled = false
      list.save!

      print "."
    rescue => e
      puts e.message
      puts list.inspect
    end
  end
end
