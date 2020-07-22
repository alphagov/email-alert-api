RSpec.describe UpdateEmailStatusService do
  describe ".call" do
    let!(:email) { create(:pending_email) }

    shared_examples "email finished_sending_at timestamp" do
      it "changes the email finished_sending_at timestamp" do
        expect { described_class.call(delivery_attempt) }
          .to change { email.reload.finished_sending_at }
          .from(nil)
          .to(delivery_attempt.reload.finished_sending_at)
      end
    end

    context "when a delivery attempt is the first temporary failure" do
      let(:delivery_attempt) do
        create(:temporary_failure_delivery_attempt, email: email)
      end

      it "doesn't change email status" do
        expect { described_class.call(delivery_attempt) }
          .not_to change { email.reload.status }
          .from("pending")
      end

      it "doesn't change the email finished_sending_at timestamp" do
        expect { described_class.call(delivery_attempt) }
          .not_to change { email.reload.finished_sending_at }
          .from(nil)
      end
    end

    context "when a delivery attempt is a temporary failure and there was a previous one over 24 hours ago" do
      before do
        create(:temporary_failure_delivery_attempt, email: email, completed_at: 25.hours.ago)
      end

      let(:delivery_attempt) do
        create(:temporary_failure_delivery_attempt, email: email)
      end

      it "marks an email as failed" do
        expect { described_class.call(delivery_attempt) }
          .to change { email.reload.status }
          .to("failed")
      end

      include_examples "email finished_sending_at timestamp"
    end

    context "when a delivery attempt is a technical failure" do
      let(:delivery_attempt) do
        create(:technical_failure_delivery_attempt, email: email)
      end

      it "marks an email as failed" do
        expect { described_class.call(delivery_attempt) }
          .to change { email.reload.status }
          .to("failed")
      end
      include_examples "email finished_sending_at timestamp"
    end

    context "when a delivery attempt is delivered" do
      let(:delivery_attempt) do
        create(:delivered_delivery_attempt, email: email)
      end

      it "marks an email as sent" do
        expect { described_class.call(delivery_attempt) }
          .to change { email.reload.status }
          .to("sent")
      end
      include_examples "email finished_sending_at timestamp"
    end

    context "when a delivery attempt is a permanent failure" do
      let(:delivery_attempt) do
        create(:permanent_failure_delivery_attempt, email: email)
      end

      it "marks an email as failed" do
        expect { described_class.call(delivery_attempt) }
          .to change { email.reload.status }
          .to("failed")
      end

      include_examples "email finished_sending_at timestamp"
    end
  end
end
