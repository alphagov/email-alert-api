RSpec.describe Healthcheck::DigestRuns do
  shared_examples "an ok healthcheck" do
    specify { expect(subject.status).to eq(:ok) }
  end

  shared_examples "a warning healthcheck" do
    specify { expect(subject.status).to eq(:warning) }
  end

  shared_examples "a critical healthcheck" do
    specify { expect(subject.status).to eq(:critical) }
  end

  context "when a content change was created 5 minute ago" do
    before { create(:digest_run, created_at: 5.minutes.ago) }
    it_behaves_like "an ok healthcheck"
  end

  context "when a content change was created 30 minutes ago" do
    before { create(:digest_run, created_at: 30.minutes.ago) }
    it_behaves_like "a warning healthcheck"
  end

  context "when a content change was created 60 minutes ago" do
    before { create(:digest_run, created_at: 60.minutes.ago) }
    it_behaves_like "a critical healthcheck"
  end
end
