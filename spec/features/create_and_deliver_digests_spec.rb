require "rails_helper"

RSpec.describe "creating and delivering digests", type: :request do
  before do
    Timecop.freeze "2017-01-02 10:00"

    allow_any_instance_of(DeliveryRequestService)
      .to receive(:provider_name).and_return("notify")

    stub_notify
  end

  after do
    Timecop.return
  end

  def base_path
    "http://www.dev.gov.uk/base-path?"
  end

  def first_expected_daily_email_body(subscription_one, subscription_two, content_change_one, content_change_two, content_change_three, content_change_four, subscriber)
    <<~BODY
      Daily update from GOV.UK.

      #Subscriber list one&nbsp;

      [Title one](#{base_path}#{utm_params(content_change_one.id, 'daily')})

      Page summary
      Description one

      Change made
      Change note one

      Time updated
      10:00am, 1 January 2017

      ---

      [Title two](#{base_path}#{utm_params(content_change_two.id, 'daily')})

      Page summary
      Description two

      Change made
      Change note two

      Time updated
      9:00am, 1 January 2017

      ---

      [Unsubscribe from ‘Subscriber list one’](http://www.dev.gov.uk/email/unsubscribe/#{subscription_one.id}?title=Subscriber%20list%20one)

      &nbsp;

      #Subscriber list two&nbsp;

      [Title four](#{base_path}#{utm_params(content_change_four.id, 'daily')})

      Page summary
      Description four

      Change made
      Change note four

      Time updated
      9:30am, 1 January 2017

      ---

      [Title three](#{base_path}#{utm_params(content_change_three.id, 'daily')})

      Page summary
      Description three

      Change made
      Change note three

      Time updated
      9:00am, 1 January 2017

      ---

      [Unsubscribe from ‘Subscriber list two’](http://www.dev.gov.uk/email/unsubscribe/#{subscription_two.id}?title=Subscriber%20list%20two)


      &nbsp;

      ---

      ^You’re getting this email because you subscribed to daily updates on these topics on GOV.UK.

      [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})

      Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).
    BODY
  end

  def second_expected_daily_email_body(subscription, content_change_one, content_change_two, subscriber)
    <<~BODY
      Daily update from GOV.UK.

      #Subscriber list one&nbsp;

      [Title one](#{base_path}#{utm_params(content_change_one.id, 'daily')})

      Page summary
      Description one

      Change made
      Change note one

      Time updated
      10:00am, 1 January 2017

      ---

      [Title two](#{base_path}#{utm_params(content_change_two.id, 'daily')})

      Page summary
      Description two

      Change made
      Change note two

      Time updated
      9:00am, 1 January 2017

      ---

      [Unsubscribe from ‘Subscriber list one’](http://www.dev.gov.uk/email/unsubscribe/#{subscription.id}?title=Subscriber%20list%20one)


      &nbsp;

      ---

      ^You’re getting this email because you subscribed to daily updates on these topics on GOV.UK.

      [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})

      Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).
    BODY
  end

  scenario "daily digest run" do
    login_with_internal_app

    #create two subscriber lists with different links
    list_one_topic_id = "0eb5d0f0-d384-4f27-9da8-3f9e9b22a820"
    list_two_topic_id = "a915e039-070b-4633-813d-187af61cad7a"

    subscriber_list_one_id = create_subscriber_list(title: "Subscriber list one", links: {
      topics: { any: [list_one_topic_id] }
    })

    subscriber_list_two_id = create_subscriber_list(title: "Subscriber list two", links: {
      topics: { any: [list_two_topic_id] }
    })

    #create two daily subscribers, one subscribed to daily digests for both
    #subscriber_lists and the other for daily for subscriber_list_one only
    subscriber_one_address = "test-one@example.com"
    subscriber_two_address = "test-two@example.com"

    #subscriber that shouldn't receive a digest
    non_digest_subscriber_address = "test-three@example.com"

    subscribe_to_subscriber_list(
      subscriber_list_one_id,
      address: subscriber_one_address,
      frequency: Frequency::DAILY
    )

    subscribe_to_subscriber_list(
      subscriber_list_two_id,
      address: subscriber_one_address,
      frequency: Frequency::DAILY
    )

    subscribe_to_subscriber_list(
      subscriber_list_one_id,
      address: subscriber_two_address,
      frequency: Frequency::DAILY
    )

    subscribe_to_subscriber_list(
      subscriber_list_one_id,
      address: non_digest_subscriber_address,
      frequency: Frequency::IMMEDIATELY
    )

    #publish two items to each list
    Timecop.freeze "2017-01-01 09:30:00" do
      create_content_change(
        title: "Title one",
        content_id: SecureRandom.uuid,
        description: "Description one",
        change_note: "Change note one",
        public_updated_at: "2017-01-01 10:00:00",
        links: {
          topics: [list_one_topic_id]
        }
      )
    end

    Timecop.freeze "2017-01-01 09:30:01" do
      create_content_change(
        title: "Title two",
        content_id: SecureRandom.uuid,
        description: "Description two",
        change_note: "Change note two",
        public_updated_at: "2017-01-01 09:00:00",
        links: {
          topics: [list_one_topic_id, list_two_topic_id]
        }
      )
    end

    Timecop.freeze "2017-01-01 09:30:02" do
      create_content_change(
        title: "Title three",
        content_id: SecureRandom.uuid,
        description: "Description three",
        change_note: "Change note three",
        public_updated_at: "2017-01-01 09:00:00",
        links: {
          topics: [list_two_topic_id]
        }
      )
    end

    Timecop.freeze "2017-01-01 09:30:03" do
      create_content_change(
        title: "Title four",
        content_id: SecureRandom.uuid,
        description: "Description four",
        change_note: "Change note four",
        public_updated_at: "2017-01-01 09:30:00",
        links: {
          topics: [list_two_topic_id]
        }
      )
    end

    #TODO retrieve this via the API when we have an endpoint
    subscriptions = Subscription.all
    content_changes = ContentChange.order(:created_at)
    subscribers = Subscriber.all

    first_digest_stub = stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(body: hash_including(email_address: "test-one@example.com"))
      .with(body: hash_including(personalisation: hash_including("subject" => "Daily update from GOV.UK")))
      .with(
        body: hash_including(
          personalisation: hash_including(
            "body" => first_expected_daily_email_body(subscriptions[0], subscriptions[1], content_changes[0], content_changes[1], content_changes[2], content_changes[3], subscribers[0])
          )
        )
      )
      .to_return(body: {}.to_json)

    second_digest_stub = stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(body: hash_including(email_address: "test-two@example.com"))
      .with(body: hash_including(personalisation: hash_including("subject" => "Daily update from GOV.UK")))
      .with(
        body: hash_including(
          personalisation: hash_including(
            "body" => second_expected_daily_email_body(subscriptions[2], content_changes[0], content_changes[1], subscribers[1])
          )
        )
      )
      .to_return(body: {}.to_json)

    DailyDigestInitiatorWorker.new.perform
    Sidekiq::Worker.drain_all

    expect(first_digest_stub).to have_been_requested
    expect(second_digest_stub).to have_been_requested
  end

  def first_expected_weekly_email_body(subscription_one, subscription_two, content_change_one, content_change_two, content_change_three, content_change_four, subscriber)
    <<~BODY
      Updates on GOV.UK this week.

      #Subscriber list one&nbsp;

      [Title one](#{base_path}#{utm_params(content_change_one.id, 'weekly')})

      Page summary
      Description one

      Change made
      Change note one

      Time updated
      10:00am, 28 December 2016

      ---

      [Title two](#{base_path}#{utm_params(content_change_two.id, 'weekly')})

      Page summary
      Description two

      Change made
      Change note two

      Time updated
      9:00am, 27 December 2016

      ---

      [Unsubscribe from ‘Subscriber list one’](http://www.dev.gov.uk/email/unsubscribe/#{subscription_one.id}?title=Subscriber%20list%20one)

      &nbsp;

      #Subscriber list two&nbsp;

      [Title four](#{base_path}#{utm_params(content_change_four.id, 'weekly')})

      Page summary
      Description four

      Change made
      Change note four

      Time updated
      9:30am, 1 January 2017

      ---

      [Title three](#{base_path}#{utm_params(content_change_three.id, 'weekly')})

      Page summary
      Description three

      Change made
      Change note three

      Time updated
      9:00am, 30 December 2016

      ---

      [Unsubscribe from ‘Subscriber list two’](http://www.dev.gov.uk/email/unsubscribe/#{subscription_two.id}?title=Subscriber%20list%20two)


      &nbsp;

      ---

      ^You’re getting this email because you subscribed to weekly updates on these topics on GOV.UK.

      [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})

      Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).
    BODY
  end

  def second_expected_weekly_email_body(subscription, content_change_one, content_change_two, subscriber)
    <<~BODY
      Updates on GOV.UK this week.

      #Subscriber list one&nbsp;

      [Title one](#{base_path}#{utm_params(content_change_one.id, 'weekly')})

      Page summary
      Description one

      Change made
      Change note one

      Time updated
      10:00am, 28 December 2016

      ---

      [Title two](#{base_path}#{utm_params(content_change_two.id, 'weekly')})

      Page summary
      Description two

      Change made
      Change note two

      Time updated
      9:00am, 27 December 2016

      ---

      [Unsubscribe from ‘Subscriber list one’](http://www.dev.gov.uk/email/unsubscribe/#{subscription.id}?title=Subscriber%20list%20one)


      &nbsp;

      ---

      ^You’re getting this email because you subscribed to weekly updates on these topics on GOV.UK.

      [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})

      Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).
    BODY
  end
  scenario "weekly digest run" do
    login_with_internal_app

    #create two subscriber lists with different links
    list_one_topic_id = "0eb5d0f0-d384-4f27-9da8-3f9e9b22a820"
    list_one_taxon_id = "86db0cbd-a1f9-4218-b571-ca0550265e33"
    list_two_taxon_id = "6416e4e0-c0c1-457a-8337-4bf8ed9d5f80"

    subscriber_list_one_id = create_subscriber_list(title: "Subscriber list one", links: {
      topics: { any: [list_one_topic_id] }
    })

    subscriber_list_two_id = create_subscriber_list(title: "Subscriber list two", links: {
      taxon_tree: { all: [list_one_taxon_id, list_two_taxon_id] }
    })

    #create two daily subscribers, one subscribed to daily digests for both
    #subscriber_lists and the other for daily for subscriber_list_one only
    subscriber_one_address = "test-one@example.com"
    subscriber_two_address = "test-two@example.com"

    non_weekly_digest_subscriber_address = "test-three@example.com"

    subscribe_to_subscriber_list(
      subscriber_list_one_id,
      address: subscriber_one_address,
      frequency: Frequency::WEEKLY
    )

    subscribe_to_subscriber_list(
      subscriber_list_two_id,
      address: subscriber_one_address,
      frequency: Frequency::WEEKLY
    )

    subscribe_to_subscriber_list(
      subscriber_list_one_id,
      address: subscriber_two_address,
      frequency: Frequency::WEEKLY
    )

    subscribe_to_subscriber_list(
      subscriber_list_two_id,
      address: non_weekly_digest_subscriber_address,
      frequency: Frequency::DAILY
    )

    #publish two items to each list
    Timecop.freeze "2016-12-28 10:00" do
      create_content_change(
        title: "Title one",
        content_id: SecureRandom.uuid,
        description: "Description one",
        change_note: "Change note one",
        public_updated_at: "2016-12-28 10:00:00",
        links: {
          topics: [list_one_topic_id]
        }
      )
    end

    Timecop.freeze "2016-12-27 09:00" do
      create_content_change(
        title: "Title two",
        content_id: SecureRandom.uuid,
        description: "Description two",
        change_note: "Change note two",
        public_updated_at: "2016-12-27 09:00:00",
        links: {
          topics: [list_one_topic_id]
        }
      )
    end

    Timecop.freeze "2016-12-30 09:00:00" do
      create_content_change(
        title: "Title three",
        content_id: SecureRandom.uuid,
        description: "Description three",
        change_note: "Change note three",
        public_updated_at: "2016-12-30 09:00:00",
        links: {
          taxon_tree: [list_one_taxon_id, list_two_taxon_id]
        }
      )
    end

    Timecop.freeze "2017-01-01 09:30:00" do
      create_content_change(
        title: "Title four",
        content_id: SecureRandom.uuid,
        description: "Description four",
        change_note: "Change note four",
        public_updated_at: "2017-01-01 09:30:00",
        links: {
          taxon_tree: [SecureRandom.uuid,
                       list_two_taxon_id,
                       SecureRandom.uuid,
                       list_one_taxon_id,
                       SecureRandom.uuid]
        }
      )
    end

    #TODO retrieve this via the API when we have an endpoint
    subscriptions = Subscription.all
    content_changes = ContentChange.all
    subscribers = Subscriber.all

    first_digest_stub = stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(body: hash_including(email_address: "test-one@example.com"))
      .with(body: hash_including(personalisation: hash_including("subject" => "Weekly update from GOV.UK")))
      .with(
        body: hash_including(
          personalisation: hash_including(
            "body" => first_expected_weekly_email_body(subscriptions[0], subscriptions[1], content_changes[0], content_changes[1], content_changes[2], content_changes[3], subscribers[0])
          )
        )
      )
      .to_return(body: {}.to_json)

    second_digest_stub = stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(body: hash_including(email_address: "test-two@example.com"))
      .with(body: hash_including(personalisation: hash_including("subject" => "Weekly update from GOV.UK")))
      .with(
        body: hash_including(
          personalisation: hash_including(
            "body" => second_expected_weekly_email_body(subscriptions[2], content_changes[0], content_changes[1], subscribers[1])
          )
        )
      )
      .to_return(body: {}.to_json)

    WeeklyDigestInitiatorWorker.new.perform
    Sidekiq::Worker.drain_all

    expect(first_digest_stub).to have_been_requested
    expect(second_digest_stub).to have_been_requested
  end
end
