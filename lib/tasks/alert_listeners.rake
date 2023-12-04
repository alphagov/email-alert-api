ALERT_SLUGS = %w[
  medical-device-alerts-drug-alerts-field-safety-notice-national-patient-safety-alert-and-device-safety-information
  travel-advice-for-all-countries-travel-advice
].freeze

namespace :alert_listeners do
  desc "Verify or create medical/travel alert listener"
  task verify_or_create: :environment do |_t, _args|
    address = ENV["ALERT_LISTENER_EMAIL_ACCOUNT"]
    abort("Can't create listener: ALERT_LISTENER_EMAIL_ACCOUNT env var missing!") unless address
    subscriber_lists = SubscriberList.where(slug: ALERT_SLUGS)
    abort("Can't create listener: one or more subscriber_lists missing") if subscriber_lists.count != ALERT_SLUGS.count

    puts("Checking that #{address} subscriber exists and is subscribed to Medical Alert and Travel Advice lists")
    subscriber = Subscriber.find_or_create_by!(address:) { puts("Subscriber record missing: created") }

    subscriber_lists.each do |subscriber_list|
      Subscription.find_or_create_by(
        subscriber:,
        subscriber_list:,
        frequency: "immediately",
        source: "support_task",
      ) { puts("Subscription record for #{subscriber_list.slug} missing: created") }
    end
    puts("Subscription ready")
  end
end
