namespace :bulk do
  desc "Send a bulk email to many subscriber lists"
  task :email, [] => :environment do |_t, args|
    email_ids = BulkEmailBuilder.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists: SubscriberList.where(id: args.extras),
    )

    email_ids.each do |id|
      DeliveryRequestWorker.perform_async_in_queue(id, queue: :delivery_immediate)
    end
  end

  desc "Switch immediate subscribers of the specified list slugs to daily digest"
  task switch_to_daily_digest: :environment do |_t, args|
    lists = SubscriberList.where(slug: args.extras)
    raise "One or more lists were not found" if lists.count != args.extras.count

    subscriptions = Subscription.active.immediately.where(subscriber_list: lists)
    raise "No subscriptions to change" if subscriptions.none?

    subscribers = Subscriber.where(id: subscriptions.pluck(:subscriber_id)).index_by(&:id)
    subscriptions_by_subscriber = subscriptions.group_by(&:subscriber_id).transform_keys { |k| subscribers[k] }

    subscriptions_by_subscriber.each do |subscriber, immediate_subscriptions|
      email_id = nil

      subscriber.with_lock do
        immediate_subscriptions.each do |subscription|
          subscription.end(reason: :bulk_immediate_to_digest)

          Subscription.create!(
            subscriber_id: subscription.subscriber_id,
            subscriber_list_id: subscription.subscriber_list_id,
            frequency: :daily,
            source: :bulk_immediate_to_digest,
          )
        end

        email_id = SwitchToDailyDigestEmailBuilder.call(subscriber, immediate_subscriptions)
      end

      DeliveryRequestWorker.perform_async_in_queue(email_id, queue: :default)
    rescue StandardError => e
      puts "Skipping subscriber: #{e}"
    end
  end

  desc "Switch immediate subscribers of the following lists to daily digest (experiment)"
  task switch_to_daily_digest_experiment: :environment do
    Rake::Task["bulk:switch_to_daily_digest"].invoke(
      "news-and-communications-2",
      "guidance-and-regulation-2",
      "guidance-and-regulation",
      "guidance-about-all-topics-by-all-organisations",
      "news-and-communications-3",
      "news-and-communications",
      "all-announcements-about-all-topics-by-all-organisations",
      "business-and-industry",
      "crime-justice-and-law",
      "statistics",
      "government-efficiency-transparency-and-accountability-2",
      "press-releases-about-all-topics-by-all-organisations",
      "environment-agency",
      "corporate-information",
      "all-types-of-document-about-all-topics-by-department-for-environment-food-rural-affairs",
      "department-for-environment-food-rural-affairs",
      "hm-revenue-customs",
      "animal-and-plant-health-agency",
      "ministry-of-defence",
      "car-driving-tests",
      "car-motorcycle-and-van-mot-tests",
      "business-tax-self-employment",
      "driving-and-motorcycle-tests",
      "ofsted",
      "rail-accident-investigation-branch",
      "correspondence-related-to-education-and-education-and-skills-funding-agency-2",
      "news-stories-about-all-topics-by-department-of-health-and-social-care",
      "department-for-education",
      "international-development-funding",
      "the-charity-commission",
      "theory-tests",
      "standards-and-testing-agency",
      "personal-tax-self-assessment",
      "planning-and-development-planning-officer-guidance",
      "civil-service-fast-track-apprenticeship",
      "further-education-and-skills-apprenticeships",
    )
  end
end
