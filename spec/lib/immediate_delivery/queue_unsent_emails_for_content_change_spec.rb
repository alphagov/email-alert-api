RSpec.describe ImmediateDelivery::QueueUnsentEmailsForContentChange do
  let(:content_change_travel_advice) { create(:content_change) }
  let(:email_travel_advice) { create(:email) }
  let(:email_travel_advice_two) { create(:email) }

  let(:content_change_other) { create(:content_change) }
  let(:email_other) { create(:email) }

  before :each do
    create(:subscription_content, content_change: content_change_travel_advice, email: email_travel_advice)
    create(:subscription_content, content_change: content_change_travel_advice, email: email_travel_advice_two)
    create(:subscription_content, content_change: content_change_other, email: email_other)
  end

  around(:example) do |example|
    Sidekiq::Testing.fake! do
      example.run
    end
  end

  it "should send emails related to travel advice subscription content" do
    expect(DeliveryRequestWorker).to receive(:perform_async_in_queue).with(email_travel_advice.id, queue: :delivery_immediate_high)
    expect(DeliveryRequestWorker).to receive(:perform_async_in_queue).with(email_travel_advice_two.id, queue: :delivery_immediate_high)
    described_class.call(content_change_id: content_change_travel_advice.id)
  end

  it "should not send emails that are related to other content changes" do
    expect(DeliveryRequestWorker).not_to receive(:perform_async_in_queue).with(email_other.id, queue: :delivery_immediate_high)
    described_class.call(content_change_id: content_change_travel_advice.id)
  end
end
