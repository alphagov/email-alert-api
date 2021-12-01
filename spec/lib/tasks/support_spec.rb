RSpec.describe "support" do
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

  describe "unsubscribe_all_brexit_checker_subscriptions" do
    before do
      Rake::Task["support:unsubscribe_all_brexit_checker_subscriptions"].reenable
    end

    it "ends all Brexit checker subscriptions" do
      subscription = create :subscription, :brexit_checker

      expect {
        Rake::Task["support:unsubscribe_all_brexit_checker_subscriptions"].invoke
      }.to output.to_stdout

      expect(subscription.reload).to be_ended
    end

    it "does not update already unsubscribed subscriptions" do
      ended_at = Time.zone.now - 1.week
      subscription = create :subscription, :brexit_checker
      subscription.update!(ended_at: ended_at)

      expect {
        Rake::Task["support:unsubscribe_all_brexit_checker_subscriptions"].invoke
      }.to output("Unsubscribing 0 subscriptions\n").to_stdout

      expect(subscription.ended_at).to be_within(1.second).of ended_at
    end

    it "only unsubscribes Brexit checker subscriptions" do
      create :subscription, :brexit_checker
      subscription = create :subscription

      expect {
        Rake::Task["support:unsubscribe_all_brexit_checker_subscriptions"].invoke
      }.to output("Unsubscribing 1 subscriptions\n").to_stdout

      expect(subscription.ended_at).to be_nil
    end
  end
end
