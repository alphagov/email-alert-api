RSpec.describe SubscriptionContentWorker do
  it "delegates to ProcessContentChange" do
    content_change = create(:content_change)
    expect_any_instance_of(ProcessContentChangeWorker)
      .to receive(:perform).with(content_change.id).and_call_original
    subject.perform(content_change.id)
  end
end
