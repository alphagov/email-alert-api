# We're retiring topics for open/closed consultation subscriptions from the
# GOV.UK publications page. Instead, people who sign up to any of these lists
# will receive notifications for all consultations.
#
# This class notifies subscribers of those topics about what is changing and
# performs the cleanup operation in govdelivery and deletes the subscriber lists
# from this application's database.

class OpenClosedRetirer
  TOPIC_FOR_MANUAL_TESTING = "UKGOVUK_55555"

  attr_accessor :topics_to_retire

  def initialize(run_for_real: false)
    if run_for_real
      self.topics_to_retire = open_consultation_topics + closed_consultation_topics
    else
      puts "Manual test mode: #{TOPIC_FOR_MANUAL_TESTING}."
      self.topics_to_retire = [TOPIC_FOR_MANUAL_TESTING]
    end
  end

  def notify_subscribers_about_retirement!
    args = [topics_to_retire, subject, body]
    puts "Sending bulletin with args: #{args.inspect}"

    Services.gov_delivery.send_bulletin(*args)
  end

  def remove_subscriber_lists_and_topics!
    topics_to_retire.each do |topic|
      begin
        Services.gov_delivery.delete_topic(topic)
        SubscriberList.find_by!(gov_delivery_id: topic).destroy
        puts "#{topic} removed"
      rescue => e
        puts "Failed to remove #{topic}: #{e.message}"
      end
    end
  end

  private

  def subject
    "Changes to your email subscription"
  end

  def body
    <<-HTML
      <h1>Changes to your subscription</h1>
      <p>We’re changing the way we send out emails about consultations.</p>
      <p>The list you’re currently subscribed to is being retired.</p>
      <h2>Resubscribe to get emails about all consultations</h2>
      <p>You can <a href="https://www.gov.uk/government/publications?publication_filter_option=consultations">sign up to get email alerts about all consultations</a> instead.</p>
      <p><a href="[[SUBSCRIBER_PREFERENCES_URL]]">Update your email preferences</a> to change the kind of emails you get and how often you get them.</p>
    HTML
  end

  def open_consultation_topics
    SubscriberList.where(government_document_supertype: "open-consultations").pluck(:gov_delivery_id)
  end

  def closed_consultation_topics
    SubscriberList.where(government_document_supertype: "closed-consultations").pluck(:gov_delivery_id)
  end
end
