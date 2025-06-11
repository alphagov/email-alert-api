RSpec.describe "support" do
  describe "stats_for_content_id" do
    after(:each) do
      Rake::Task["support:emails:stats_for_content_id"].reenable
    end

    context "with invalid dates" do
      it "outputs all subscriptions for a subscriber" do
        expect { Rake::Task["support:emails:stats_for_content_id"].invoke(SecureRandom.uuid, "bad_date", "bad_date") }
          .to raise_error(SystemExit, /Cannot parse dates/)
      end
    end

    context "with matching emails" do
      let(:valid_email) { create(:email, content_id: SecureRandom.uuid) }

      it "outputs all subscriptions for a subscriber" do
        expect { Rake::Task["support:emails:stats_for_content_id"].invoke(valid_email.content_id) }
          .to output(/1 emails sent/).to_stdout
      end
    end

    context "without matching emails" do
      it "outputs all subscriptions for a subscriber" do
        expect { Rake::Task["support:emails:stats_for_content_id"].invoke(SecureRandom.uuid) }
          .to output(/No emails sent/).to_stdout
      end
    end
  end

  describe "get_notifications_from_notify_by_email_id" do
    before { stub_request(:get, /notifications\.service\.gov\.uk/).to_return(status: 404) }

    it "outputs the status of notifications with a specified email ID" do
      expect { Rake::Task["support:get_notifications_from_notify_by_email_id"].invoke("1") }
        .to output.to_stdout
    end
  end

  describe "send_test_email" do
    it "queues a test email to a test email address" do
      expect(SendEmailJob).to receive(:perform_async_in_queue)

      expect { Rake::Task["support:send_test_email"].invoke("foo@bar.com") }
        .to change { Email.count }.by 1
    end
  end

  describe "view_emails" do
    after(:each) do
      Rake::Task["support:view_emails"].reenable
    end

    it "displays error message if email is not provided" do
      expect { Rake::Task["support:view_emails"].invoke }
        .to raise_error(ArgumentError, /Provide an email!/)
    end

    it "outputs the latest emails sent to an email address" do
      expect { Rake::Task["support:view_emails"].invoke("foo@example.org", 1) }
        .to output.to_stdout
    end
  end

  describe "resend_failed_emails:by_id" do
    before { Rake::Task["support:resend_failed_emails:by_id"].reenable }

    it "queues specified failed emails to resend" do
      email = create :email, status: :failed

      expect(SendEmailJob).to receive(:perform_async_in_queue)
        .with(email.id, queue: :send_email_immediate_high)

      expect { Rake::Task["support:resend_failed_emails:by_id"].invoke(email.id.to_s) }
        .to output.to_stdout
    end

    it "updates the failed emails' status to pending" do
      allow(SendEmailJob).to receive(:perform_async_in_queue)

      email = create :email, status: :failed

      freeze_time do
        expect { Rake::Task["support:resend_failed_emails:by_id"].invoke(email.id.to_s) }
          .to output.to_stdout
          .and change { email.reload.status }.to("pending")
          .and change { email.reload.updated_at }.to(Time.zone.now)
      end
    end
  end

  describe "resend_failed_emails:by_date" do
    before { Rake::Task["support:resend_failed_emails:by_date"].reenable }

    let(:from) { 1.day.ago.iso8601 }
    let(:to) { 1.day.from_now.iso8601 }

    it "queues specified failed emails to resend" do
      email = create :email, status: :failed

      expect(SendEmailJob).to receive(:perform_async_in_queue)
        .with(email.id, queue: :send_email_immediate_high)

      expect { Rake::Task["support:resend_failed_emails:by_date"].invoke(from, to) }
        .to output.to_stdout
    end

    it "updates the failed emails' status to pending" do
      allow(SendEmailJob).to receive(:perform_async_in_queue)

      email = create :email, status: :failed

      freeze_time do
        expect { Rake::Task["support:resend_failed_emails:by_date"].invoke(from, to) }
          .to output.to_stdout
          .and change { email.reload.status }.to("pending")
          .and change { email.reload.updated_at }.to(Time.zone.now)
      end
    end
  end

  describe "#unsubscribe_all_subscribers_from_subscription" do
    after(:each) do
      Rake::Task["support:unsubscribe_all_subscribers_from_subscription"].reenable
    end

    it "outputs an error message to the user if subscription list is not found" do
      expect { Rake::Task["support:unsubscribe_all_subscribers_from_subscription"].invoke("invalid-subscription-list") }
      .to raise_error(SystemExit, /Cannot find subscriber list invalid-subscription-list/)
    end

    it "successfully unsubscribes active subscribers from valid subscription list" do
      subscriber = create(:subscriber, address: "subscribed@test.com")
      subscriber_list = create(:subscriber_list, slug: "my-list", title: "My List")
      active_subscription = create(:subscription, subscriber_list:, subscriber:)

      expect { Rake::Task["support:unsubscribe_all_subscribers_from_subscription"].invoke("my-list") }
      .to output("Unsubscribing subscribed@test.com from my-list\n").to_stdout
      .and change { active_subscription.reload.ended_reason }
      .from(nil)
      .to("unsubscribed")
    end

    it "displays message if subscriber has already been unsubscribed from valid subscription list" do
      subscriber = create(:subscriber, address: "unsubscribed@test.com")
      subscriber_list = create(:subscriber_list, slug: "another-list", title: "Another List")
      create(:subscription, :ended, subscriber_list:, subscriber:)

      expect { Rake::Task["support:unsubscribe_all_subscribers_from_subscription"].invoke("another-list") }
      .to output(/Subscriber unsubscribed@test.com already unsubscribed from another-list/).to_stdout
    end
  end

  describe "unsubscribe_single_subscription" do
    before do
      @subscriber_list = create(:subscriber_list, slug: "my-list", title: "My List")
    end

    after(:each) do
      Rake::Task["support:unsubscribe_single_subscription"].reenable
    end

    it "displays error message if subscriber is not found" do
      expect { Rake::Task["support:unsubscribe_single_subscription"].invoke("test@example.com", "my-list") }
      .to output(/Subscriber test@example.com not found/).to_stdout
    end

    it "displays error message if subscriber list is not found but subscriber exists" do
      create(:subscriber, address: "test-1@example.com")

      expect { Rake::Task["support:unsubscribe_single_subscription"].invoke("test-1@example.com", "invalid-subscription-list") }
      .to output(/Subscriber list invalid-subscription-list not found/).to_stdout
    end

    it "displays error message if subscriber is not subscribed to subscriber list" do
      create(:subscriber, address: "notsubscribed@example.com")

      expect { Rake::Task["support:unsubscribe_single_subscription"].invoke("notsubscribed@example.com", "my-list") }
      .to output(/Subscriber notsubscribed@example.com does not appear to be signed up for my-list/).to_stdout
    end

    it "successfully unsubscribes an active subscriber" do
      subscriber = create(:subscriber, address: "subscribed@example.com")
      active_subscription = create(:subscription, subscriber_list: @subscriber_list, subscriber:)

      expect { Rake::Task["support:unsubscribe_single_subscription"].invoke("subscribed@example.com", "my-list") }
      .to output(/Unsubscribing subscribed@example.com from my-list/).to_stdout
      .and change { active_subscription.reload.ended_reason }
      .from(nil)
      .to("unsubscribed")
    end

    it "displays message if subscriber has already been unsubscribed" do
      subscriber = create(:subscriber, address: "unsubscribed@example.com")
      create(:subscription, :ended, subscriber_list: @subscriber_list, subscriber:)

      expect { Rake::Task["support:unsubscribe_single_subscription"].invoke("unsubscribed@example.com", "my-list") }
      .to output(/Subscriber unsubscribed@example.com already unsubscribed from my-list/).to_stdout
    end
  end

  describe "unsubscribe_all_subscriptions" do
    after(:each) do
      Rake::Task["support:unsubscribe_all_subscriptions"].reenable
    end

    it "displays error essage if the subscriber is not found" do
      expect { Rake::Task["support:unsubscribe_all_subscriptions"].invoke("test@example.com") }
      .to output(/Subscriber test@example.com not found/).to_stdout
    end

    it "displays message if user has been unsubscribed" do
      subscriber_list1 = create(:subscriber_list, slug: "my-list", title: "My List")
      subscriber_list2 = create(:subscriber_list, slug: "another-list", title: "another List")
      subscriber = create(:subscriber, address: "subscribed@example.com")
      active_subscription1 = create(:subscription, subscriber_list: subscriber_list1, subscriber:)
      active_subscription2 = create(:subscription, subscriber_list: subscriber_list2, subscriber:)

      expect { Rake::Task["support:unsubscribe_all_subscriptions"].invoke("subscribed@example.com") }
      .to output(/Unsubscribing subscribed@example.com/).to_stdout
      .and change { active_subscription1.reload.ended_reason }
      .from(nil)
      .to("unsubscribed")
      .and change { active_subscription2.reload.ended_reason }
      .from(nil)
      .to("unsubscribed")
    end
  end

  describe "change_email_address" do
    after(:each) do
      Rake::Task["support:change_email_address"].reenable
    end

    it "displays error message and aborts if email address is not found" do
      expect { Rake::Task["support:change_email_address"].invoke("old@example.com", "new@example.com") }
      .to raise_error(SystemExit, /Cannot find any subscriber with email address old@example.com/)
    end

    it "displays message when email address for subsciber has been changed" do
      subscriber = create(:subscriber, address: "old@example.com")

      expect { Rake::Task["support:change_email_address"].invoke("old@example.com", "new@example.com") }
      .to output(/Changed email address for old@example.com to new@example.com/).to_stdout
      .and change { subscriber.reload.address }
      .from("old@example.com")
      .to("new@example.com")
    end
  end

  describe "view_subscriptions" do
    after(:each) do
      Rake::Task["support:view_subscriptions"].reenable
    end

    it "displays error message and aborts if email address is not found" do
      expect { Rake::Task["support:view_subscriptions"].invoke("test@example.com") }
      .to raise_error(SystemExit, /Cannot find any subscriber with email address test@example.com/)
    end

    it "displays all subscriptions for a subscriber" do
      subscriber = create(:subscriber, address: "test@example.com")
      subscriber_list1 = create(:subscriber_list, slug: "my-list", title: "My List")
      subscriber_list2 = create(:subscriber_list, slug: "another-list", title: "Another List")
      subscription1 = create(:subscription, subscriber_list: subscriber_list1, subscriber:)
      subscription2 = create(:subscription, :ended, subscriber_list: subscriber_list2, subscriber:)

      report = <<~TEXT
        [{:status=>"Active",
          :subscriber_list=>"#{subscriber_list1.title} (slug: #{subscriber_list1.slug})",
          :frequency=>"#{subscription1.frequency}",
          :timeline=>"Subscribed #{subscription1.created_at}"},
         {:status=>"Inactive (#{subscription2.ended_reason})",
          :subscriber_list=>"#{subscriber_list2.title} (slug: #{subscriber_list2.slug})",
          :frequency=>"#{subscription2.frequency}",
          :timeline=>
           "Subscribed #{subscription2.created_at}, Ended #{subscription2.ended_at}"}]
      TEXT

      expect { Rake::Task["support:view_subscriptions"].invoke("test@example.com") }
      .to output(report).to_stdout
    end
  end
end
