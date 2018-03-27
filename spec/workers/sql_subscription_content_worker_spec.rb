RSpec.describe SqlSubscriptionContentWorker do
  let(:content_change) { create(:content_change, tags: { topics: ["oil-and-gas/licensing"] }) }
  let(:email) { create(:email) }

  before do
    allow(ContentChange).to receive(:find).with(content_change.id).and_return(content_change)
  end

  context "with a subscription" do
    let(:subscriber) { create(:subscriber) }
    let(:subscriber_list) { create(:subscriber_list, tags: { topics: ["oil-and-gas/licensing"] }) }
    let!(:matched_content_change) { create(:matched_content_change, subscriber_list: subscriber_list, content_change: content_change) }
    let!(:subscription) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list) }

    context "asynchronously" do
      it "does not raise an error" do
        expect {
          Sidekiq::Testing.fake! do
            SubscriptionContentWorker.perform_async(content_change.id)
            described_class.drain
          end
        }.not_to raise_error
      end
    end

    it "creates subscription content for the content change" do
      expect { subject.perform(content_change.id) }
        .to change { SubscriptionContent.count }.by(1)
    end

    it "marks the content_change as processed" do
      expect(content_change).to receive(:mark_processed!)
      subject.perform(content_change.id)
    end
  end

  context "with a courtesy subscription" do
    let!(:subscriber) do
      create(:subscriber, address: "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk")
    end

    it "creates and enqueues an email for the courtesy email group" do
      expect(ImmediateEmailBuilder)
        .to receive(:call)
        .with([hash_including(address: subscriber.address)])
        .and_return(double(ids: ["random-guid"]))

      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(kind_of(String), queue: :delivery_immediate)

      subject.perform(content_change.id)
    end
  end

  context "with an already processed content change" do
    before do
      content_change.mark_processed!
    end

    it "should return immediate" do
      expect(content_change).to_not receive(:mark_processed!)
      subject.perform(content_change.id)
    end
  end

  context "benchmarking" do
    let(:subscriber) { create(:subscriber) }
    let(:content_change) { create(:content_change) }

    before do
      1000.times do
        subscription = create(:subscription, subscriber: subscriber)
        create(:matched_content_change, subscriber_list: subscription.subscriber_list, content_change: content_change)
      end
    end

    it "reports the benchmark" do
      r = Benchmark.measure do
        subject.perform(content_change.id)
      end
      pp r
    end
  end
end
