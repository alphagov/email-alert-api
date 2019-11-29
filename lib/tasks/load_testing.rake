namespace :load_testing do
  desc "Create fake delivery attempts which can be used to load test the status updates endpoint."
  task :create_fake_delivery_attempts, [:count] => :environment do |_t, args|
    email_id = Email.last.id
    ids = args[:count].to_i.times.map { SecureRandom.uuid }
    records = ids.map do |id|
      { id: id, email_id: email_id, status: :sending, provider: "pseudo" }
    end

    DeliveryAttempt.import(records)

    path = "/tmp/delivery_attempt_ids_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}"

    File.open(path, "w") do |file|
      file.write(ids.join("\n"))
      file.write("\n")
    end

    puts "Delivery Attempt IDs available at:"
    puts path
  end
end
