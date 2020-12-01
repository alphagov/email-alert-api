RSpec.describe "create and delive a weekly digest", type: :request do
  include UTMHelpers

  scenario do
    login_with_internal_app

    # create two subscriber lists with different links
    list_one_topic_id = "0eb5d0f0-d384-4f27-9da8-3f9e9b22a820"
    list_two_taxon_id = "6416e4e0-c0c1-457a-8337-4bf8ed9d5f80"

    subscriber_list_one_id = create_subscriber_list(
      title: "Subscriber list one",
      links: {
        topics: { any: [list_one_topic_id] },
      },
    )

    subscriber_list_two_id = create_subscriber_list(
      title: "Subscriber list two",
      links: {
        taxon_tree: { all: [list_two_taxon_id] },
      },
    )

    # create two daily subscribers, one subscribed to daily digests for both
    # subscriber_lists and the other for daily for subscriber_list_one only
    subscriber_one_address = "test-one@example.com"
    subscriber_two_address = "test-two@example.com"

    non_weekly_digest_subscriber_address = "test-three@example.com"

    subscribe_to_subscriber_list(
      subscriber_list_one_id,
      address: subscriber_one_address,
      frequency: Frequency::WEEKLY,
    )

    subscribe_to_subscriber_list(
      subscriber_list_two_id,
      address: subscriber_one_address,
      frequency: Frequency::WEEKLY,
    )

    subscribe_to_subscriber_list(
      subscriber_list_one_id,
      address: subscriber_two_address,
      frequency: Frequency::WEEKLY,
    )

    subscribe_to_subscriber_list(
      subscriber_list_two_id,
      address: non_weekly_digest_subscriber_address,
      frequency: Frequency::DAILY,
    )

    # publish two items to each list
    travel_to(Time.zone.parse("2017-01-01 09:30")) do
      create_content_change(
        title: "Title one",
        content_id: SecureRandom.uuid,
        description: "Description one",
        change_note: "Change note one",
        public_updated_at: "2017-01-01 10:00:00",
        links: {
          topics: [list_one_topic_id],
        },
      )
    end

    travel_to(Time.zone.parse("2017-01-01 09:31")) do
      create_message(
        title: "Title two",
        url: "/base-path",
        criteria_rules: [
          { type: "link", key: "topics", value: list_one_topic_id },
        ],
      )
    end

    travel_to(Time.zone.parse("2017-01-04 09:32")) do
      create_content_change(
        title: "Title three",
        content_id: SecureRandom.uuid,
        description: "Description three",
        change_note: "Change note three",
        public_updated_at: "2017-01-04 09:00:00",
        links: {
          taxon_tree: [list_two_taxon_id],
        },
      )
    end

    travel_to(Time.zone.parse("2017-01-06 09:33")) do
      create_content_change(
        title: "Title four",
        content_id: SecureRandom.uuid,
        description: "Description four",
        change_note: "Change note four",
        public_updated_at: "2017-01-06 09:30:00",
        links: {
          taxon_tree: [SecureRandom.uuid,
                       list_two_taxon_id,
                       SecureRandom.uuid],
        },
      )
    end

    subscriptions = Subscription.all
    content_changes = ContentChange.order(:created_at)
    messages = Message.order(:created_at)
    subscribers = Subscriber.all

    first_digest_stub = stub_notify_request(
      subscriber_one_address,
      first_expected_email_body(
        subscriptions[0],
        subscriptions[1],
        content_changes[0],
        messages[0],
        content_changes[1],
        content_changes[2],
        subscribers[0],
      ),
    )

    second_digest_stub = stub_notify_request(
      subscriber_two_address,
      second_expected_email_body(
        subscriptions[2],
        content_changes[0],
        messages[0],
        subscribers[1],
      ),
    )

    travel_to(Time.zone.parse("2017-01-07 10:00")) do
      WeeklyDigestInitiatorWorker.new.perform
      Sidekiq::Worker.drain_all
    end

    expect(first_digest_stub).to have_been_requested
    expect(second_digest_stub).to have_been_requested
  end

  def url
    "http://www.dev.gov.uk/base-path?"
  end

  def stub_notify_request(email_address, email_body)
    body = hash_including(
      email_address: email_address,
      personalisation: hash_including(
        "subject" => "Weekly update from GOV.UK",
        "body" => email_body,
      ),
    )

    stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
      .with(body: body)
      .to_return(body: {}.to_json)
  end

  def first_expected_email_body(subscription_one,
                                subscription_two,
                                content_change_one,
                                message_one,
                                content_change_two,
                                content_change_three,
                                subscriber)
    <<~BODY
      Updates on GOV.UK this week.

      # Subscriber list one &nbsp;

      [Title one](#{url}#{utm_params(content_change_one.id, 'weekly')})

      Page summary
      Description one

      Change made
      Change note one

      Time updated
      10:00am, 1 January 2017

      ---

      [Title two](#{url}#{message_utm_params(message_one.id, 'weekly')})

      Body

      ---

      [Unsubscribe from ‘Subscriber list one’](http://www.dev.gov.uk/email/unsubscribe/#{subscription_one.id})

      &nbsp;

      # Subscriber list two &nbsp;

      [Title three](#{url}#{utm_params(content_change_two.id, 'weekly')})

      Page summary
      Description three

      Change made
      Change note three

      Time updated
      9:00am, 4 January 2017

      ---

      [Title four](#{url}#{utm_params(content_change_three.id, 'weekly')})

      Page summary
      Description four

      Change made
      Change note four

      Time updated
      9:30am, 6 January 2017

      ---

      [Unsubscribe from ‘Subscriber list two’](http://www.dev.gov.uk/email/unsubscribe/#{subscription_two.id})

      ^You’re getting this email because you subscribed to weekly updates on these topics on GOV.UK.

      [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/manage/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})

      Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).
    BODY
  end

  def second_expected_email_body(subscription,
                                 content_change_one,
                                 message_one,
                                 subscriber)
    <<~BODY
      Updates on GOV.UK this week.

      # Subscriber list one &nbsp;

      [Title one](#{url}#{utm_params(content_change_one.id, 'weekly')})

      Page summary
      Description one

      Change made
      Change note one

      Time updated
      10:00am, 1 January 2017

      ---

      [Title two](#{url}#{message_utm_params(message_one.id, 'weekly')})

      Body

      ---

      [Unsubscribe from ‘Subscriber list one’](http://www.dev.gov.uk/email/unsubscribe/#{subscription.id})

      ^You’re getting this email because you subscribed to weekly updates on these topics on GOV.UK.

      [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/manage/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})

      Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).
    BODY
  end
end
