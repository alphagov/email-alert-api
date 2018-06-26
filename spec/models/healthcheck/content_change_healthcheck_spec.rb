RSpec.describe Healthcheck::ContentChangeHealthcheck do
  shared_examples "an ok healthcheck" do
    specify { expect(subject.status).to eq(:ok) }
  end

  shared_examples "a warning healthcheck" do
    specify { expect(subject.status).to eq(:warning) }
  end

  shared_examples "a critical healthcheck" do
    specify { expect(subject.status).to eq(:critical) }
  end

  context "when a content change was created 1 minute ago" do
    before do
      create(:content_change, created_at: 1.minute.ago)
    end

    it_behaves_like "an ok healthcheck"
  end

  context "when a content change was created 5 minutes ago" do
    before do
      create(:content_change, created_at: 5.minutes.ago)
    end

    it_behaves_like "a warning healthcheck"
  end

  context "when a content change was created 10 minutes ago" do
    before do
      create(:content_change, created_at: 10.minutes.ago)
    end

    it_behaves_like "a critical healthcheck"
  end
end
