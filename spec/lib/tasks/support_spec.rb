RSpec.describe "support" do
  after(:each) do
    Rake::Task["support:emails:stats_for_content_id"].reenable
  end

  describe "stats_for_content_id" do
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
      expect(SendEmailWorker).to receive(:perform_async_in_queue)

      expect { Rake::Task["support:send_test_email"].invoke("foo@bar.com") }
        .to change { Email.count }.by 1
    end
  end

  describe "view_emails" do
    it "outputs the latest emails sent to an email address" do
      expect { Rake::Task["support:view_emails"].invoke("foo@example.org") }
        .to output.to_stdout
    end
  end

  describe "resend_failed_emails:by_id" do
    before { Rake::Task["support:resend_failed_emails:by_id"].reenable }

    it "queues specified failed emails to resend" do
      email = create :email, status: :failed

      expect(SendEmailWorker).to receive(:perform_async_in_queue)
        .with(email.id, queue: :send_email_immediate_high)

      expect { Rake::Task["support:resend_failed_emails:by_id"].invoke(email.id.to_s) }
        .to output.to_stdout
    end

    it "updates the failed emails' status to pending" do
      allow(SendEmailWorker).to receive(:perform_async_in_queue)

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

      expect(SendEmailWorker).to receive(:perform_async_in_queue)
        .with(email.id, queue: :send_email_immediate_high)

      expect { Rake::Task["support:resend_failed_emails:by_date"].invoke(from, to) }
        .to output.to_stdout
    end

    it "updates the failed emails' status to pending" do
      allow(SendEmailWorker).to receive(:perform_async_in_queue)

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
end
