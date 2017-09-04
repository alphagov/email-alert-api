require "rails_helper"

RSpec.describe OpenClosedRetirer do
  let(:manual_test_topic) { "UKGOVUK_55555" }

  before do
    FactoryGirl.create(
      :subscriber_list,
      government_document_supertype: "open-consultations",
      gov_delivery_id: "TEST_123",
    )

    FactoryGirl.create(
      :subscriber_list,
      government_document_supertype: "closed-consultations",
      gov_delivery_id: "TEST_456",
    )
  end

  describe "#notify_subscribers_about_retirement!" do
    it "sends an email to the topics to retire" do

      expect(Services.gov_delivery).to receive(:send_bulletin) do |*args|
        topics, subject, body = args

        expect(topics).to eq([manual_test_topic])
        expect(subject).to match("Changes to your email subscription")
        expect(body).to include("We’re changing the way we send out emails about consultations.")
      end

      expect { subject.notify_subscribers_about_retirement! }
        .to output(/Sending bulletin with args/).to_stdout
    end

    context "when 'run_for_real' is set" do
      subject { described_class.new(run_for_real: true) }

      it "sends bulletins to the real open/closed consultation topics" do
        expect(Services.gov_delivery).to receive(:send_bulletin) do |*args|
          topics, _ = args
          expect(topics).to eq(%w(TEST_123 TEST_456))
        end

        expect { subject.notify_subscribers_about_retirement! }
          .to output(/Sending bulletin with args/).to_stdout
      end
    end
  end

  describe "#remove_subscriber_lists_and_topics!" do
    before do
      FactoryGirl.create(:subscriber_list, gov_delivery_id: manual_test_topic)
    end

    it "removes the govdelivery topics and subscriber list records" do
      expect(Services.gov_delivery).to receive(:delete_topic)
        .with(manual_test_topic)

      expect { subject.remove_subscriber_lists_and_topics! }
        .to change(SubscriberList, :count).by(-1)
        .and output(/#{manual_test_topic} removed/).to_stdout
    end

    context "when 'run_for_real' is set" do
      subject { described_class.new(run_for_real: true) }

      it "deletes the real open/closed consultation topics" do
        expect(Services.gov_delivery).to receive(:delete_topic)
          .with("TEST_123")

        expect(Services.gov_delivery).to receive(:delete_topic)
          .with("TEST_456")

        expect { subject.remove_subscriber_lists_and_topics! }
          .to change(SubscriberList, :count).by(-2)
          .and output(/TEST_456 removed/).to_stdout
      end
    end

    context "when something went wrong" do
      before do
        allow(Services.gov_delivery).to receive(:delete_topic)
          .and_raise("something went wrong")
      end

      it "prints the error message" do
        expect { subject.remove_subscriber_lists_and_topics! }
          .to change(SubscriberList, :count).by(0)
          .and output(/#{manual_test_topic}: something went wrong/).to_stdout
      end
    end
  end
end
