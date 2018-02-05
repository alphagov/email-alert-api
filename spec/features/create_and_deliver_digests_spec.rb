require "rails_helper"

RSpec.describe "creating and delivering digests", type: :request do
  before do
    Timecop.freeze "2017-01-02 10:00"

    allow_any_instance_of(DeliveryRequestService)
      .to receive(:provider_name).and_return("notify")
  end

  after do
    Timecop.return
  end

  def first_expected_daily_email_body(subscription_one, subscription_two)
    <<~BODY
      #Subscriber list one

      [Title one](http://www.dev.gov.uk/base-path)

      Change note one: Description one

      Updated at 10:00 am on 1 January 2017

      ---

      [Title two](http://www.dev.gov.uk/base-path)

      Change note two: Description two

      Updated at 09:00 am on 1 January 2017

      ---

      Unsubscribe from [Subscriber list one](http://www.dev.gov.uk/email/unsubscribe/#{subscription_one.uuid}?title=Subscriber%20list%20one)

      &nbsp;

      #Subscriber list two

      [Title four](http://www.dev.gov.uk/base-path)

      Change note four: Description four

      Updated at 09:30 am on 1 January 2017

      ---

      [Title three](http://www.dev.gov.uk/base-path)

      Change note three: Description three

      Updated at 09:00 am on 1 January 2017

      ---

      Unsubscribe from [Subscriber list two](http://www.dev.gov.uk/email/unsubscribe/#{subscription_two.uuid}?title=Subscriber%20list%20two)
    BODY
  end

  def second_expected_daily_email_body(subscription)
    <<~BODY
      #Subscriber list one

      [Title one](http://www.dev.gov.uk/base-path)

      Change note one: Description one

      Updated at 10:00 am on 1 January 2017

      ---

      [Title two](http://www.dev.gov.uk/base-path)

      Change note two: Description two

      Updated at 09:00 am on 1 January 2017

      ---

      Unsubscribe from [Subscriber list one](http://www.dev.gov.uk/email/unsubscribe/#{subscription.uuid}?title=Subscriber%20list%20one)
    BODY
  end

  scenario "daily digest run" do
    login_with_internal_app

    #create two subscriber lists with different links
    list_one_topic_id = "0eb5d0f0-d384-4f27-9da8-3f9e9b22a820"
    list_two_topic_id = "a915e039-070b-4633-813d-187af61cad7a"

    stub_govdelivery("TEST123")
    subscribable_one_id = create_subscribable(title: "Subscriber list one", links: {
      topics: [list_one_topic_id]
    })

    stub_govdelivery("TEST456")
    subscribable_two_id = create_subscribable(title: "Subscriber list two", links: {
      topics: [list_two_topic_id]
    })

    #create two daily subscribers, one subscribed to daily digests for both
    #subscribables and the other for daily for subscribable_one only
    subscriber_one_address = "test-one@example.com"
    subscriber_two_address = "test-two@example.com"

    #subscriber that shouldn't receive a digest
    non_digest_subscriber_address = "test-three@example.com"

    subscribe_to_subscribable(
      subscribable_one_id,
      address: subscriber_one_address,
      frequency: Frequency::DAILY
    )

    subscribe_to_subscribable(
      subscribable_two_id,
      address: subscriber_one_address,
      frequency: Frequency::DAILY
    )

    subscribe_to_subscribable(
      subscribable_one_id,
      address: subscriber_two_address,
      frequency: Frequency::DAILY
    )

    subscribe_to_subscribable(
      subscribable_one_id,
      address: non_digest_subscriber_address,
      frequency: Frequency::IMMEDIATELY
    )

    #publish two items to each list
    Timecop.freeze "2017-01-01 10:00" do
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

    Timecop.freeze "2017-01-01 09:00" do
      create_content_change(
        title: "Title two",
        content_id: SecureRandom.uuid,
        description: "Description two",
        change_note: "Change note two",
        public_updated_at: "2017-01-01 09:00:00",
        links: {
          topics: [list_one_topic_id]
        }
      )
    end

    Timecop.freeze "2017-01-01 09:00:00" do
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

    Timecop.freeze "2017-01-01 09:30:00" do
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

    first_digest_stub = stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(body: hash_including(email_address: "test-one@example.com"))
      .with(body: hash_including(personalisation: hash_including("subject" => "GOV.UK Daily Update")))
      .with(
        body: hash_including(
          personalisation: hash_including(
            "body" => first_expected_daily_email_body(subscriptions[0], subscriptions[1])
          )
        )
      )
      .to_return(body: {}.to_json)

    second_digest_stub = stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(body: hash_including(email_address: "test-two@example.com"))
      .with(body: hash_including(personalisation: hash_including("subject" => "GOV.UK Daily Update")))
      .with(
        body: hash_including(
          personalisation: hash_including(
            "body" => second_expected_daily_email_body(subscriptions[2])
          )
        )
      )
      .to_return(body: {}.to_json)

    DailyDigestInitiatorWorker.new.perform
    Sidekiq::Worker.drain_all

    expect(first_digest_stub).to have_been_requested
    expect(second_digest_stub).to have_been_requested
  end

  def first_expected_weekly_email_body(subscription_one, subscription_two)
    <<~BODY
      #Subscriber list one

      [Title one](http://www.dev.gov.uk/base-path)

      Change note one: Description one

      Updated at 10:00 am on 28 December 2016

      ---

      [Title two](http://www.dev.gov.uk/base-path)

      Change note two: Description two

      Updated at 09:00 am on 27 December 2016

      ---

      Unsubscribe from [Subscriber list one](http://www.dev.gov.uk/email/unsubscribe/#{subscription_one.uuid}?title=Subscriber%20list%20one)

      &nbsp;

      #Subscriber list two

      [Title four](http://www.dev.gov.uk/base-path)

      Change note four: Description four

      Updated at 09:30 am on 1 January 2017

      ---

      [Title three](http://www.dev.gov.uk/base-path)

      Change note three: Description three

      Updated at 09:00 am on 30 December 2016

      ---

      Unsubscribe from [Subscriber list two](http://www.dev.gov.uk/email/unsubscribe/#{subscription_two.uuid}?title=Subscriber%20list%20two)
    BODY
  end

  def second_expected_weekly_email_body(subscription)
    <<~BODY
      #Subscriber list one

      [Title one](http://www.dev.gov.uk/base-path)

      Change note one: Description one

      Updated at 10:00 am on 28 December 2016

      ---

      [Title two](http://www.dev.gov.uk/base-path)

      Change note two: Description two

      Updated at 09:00 am on 27 December 2016

      ---

      Unsubscribe from [Subscriber list one](http://www.dev.gov.uk/email/unsubscribe/#{subscription.uuid}?title=Subscriber%20list%20one)
    BODY
  end
  scenario "weekly digest run" do
    login_with_internal_app

    #create two subscriber lists with different links
    list_one_topic_id = "0eb5d0f0-d384-4f27-9da8-3f9e9b22a820"
    list_two_topic_id = "a915e039-070b-4633-813d-187af61cad7a"

    stub_govdelivery("TEST123")
    subscribable_one_id = create_subscribable(title: "Subscriber list one", links: {
      topics: [list_one_topic_id]
    })

    stub_govdelivery("TEST456")
    subscribable_two_id = create_subscribable(title: "Subscriber list two", links: {
      topics: [list_two_topic_id]
    })

    #create two daily subscribers, one subscribed to daily digests for both
    #subscribables and the other for daily for subscribable_one only
    subscriber_one_address = "test-one@example.com"
    subscriber_two_address = "test-two@example.com"

    non_weekly_digest_subscriber_address = "test-three@example.com"

    subscribe_to_subscribable(
      subscribable_one_id,
      address: subscriber_one_address,
      frequency: Frequency::WEEKLY
    )

    subscribe_to_subscribable(
      subscribable_two_id,
      address: subscriber_one_address,
      frequency: Frequency::WEEKLY
    )

    subscribe_to_subscribable(
      subscribable_one_id,
      address: subscriber_two_address,
      frequency: Frequency::WEEKLY
    )

    subscribe_to_subscribable(
      subscribable_two_id,
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
          topics: [list_two_topic_id]
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
          topics: [list_two_topic_id]
        }
      )
    end

    #TODO retrieve this via the API when we have an endpoint
    subscriptions = Subscription.all

    first_digest_stub = stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(body: hash_including(email_address: "test-one@example.com"))
      .with(body: hash_including(personalisation: hash_including("subject" => "GOV.UK Weekly Update")))
      .with(
        body: hash_including(
          personalisation: hash_including(
            "body" => first_expected_weekly_email_body(subscriptions[0], subscriptions[1])
          )
        )
      )
      .to_return(body: {}.to_json)

    second_digest_stub = stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(body: hash_including(email_address: "test-two@example.com"))
      .with(body: hash_including(personalisation: hash_including("subject" => "GOV.UK Weekly Update")))
      .with(
        body: hash_including(
          personalisation: hash_including(
            "body" => second_expected_weekly_email_body(subscriptions[2])
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
