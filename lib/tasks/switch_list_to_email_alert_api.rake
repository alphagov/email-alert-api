desc "Switch a subscriber list to email-alert-api from govuk-delivery"
task switch_list_to_email_alert_api: [:environment] do |_, args|
  TICK = "\e[32m✓\e[0m"
  CROSS = "\e[31m✗\e[0m"

  args.extras.each do |gov_delivery_id|
    # Enable the list in email-alert-api
    subscriber_list = SubscriberList.where(gov_delivery_id: gov_delivery_id).first
    subscriber_list.enabled = true

    if subscriber_list.save
      puts "#{TICK} #{gov_delivery_id} has been enabled in email-alert-api"
    else
      puts "#{CROSS} #{gov_delivery_id} could not be enabled in email-alert-api"

      # We don't want to disable the list in govuk-delivery if we couldn't
      # successfully enable it in email-alert-api
      exit
    end

    # Disable the list in govuk-delivery
    response = Services.govuk_delivery.disable_list(gov_delivery_id).to_hash

    if !response['enabled']
      puts "#{TICK} #{gov_delivery_id} has been disabled in govuk-delivery"
    else
      puts "#{CROSS} #{gov_delivery_id} could not be disabled in govuk-delivery - disabling in email-alert-api"

      # Disable the list in email-alert-api to keep consistency
      subscriber_list.enabled = false
      subscriber_list.save
    end
  end
end
