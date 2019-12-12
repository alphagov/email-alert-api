RSpec.describe ContentChange do
  describe "#mark_processed!" do
    subject { create(:content_change) }

    it "sets processed_at" do
      Timecop.freeze do
        expect { subject.mark_processed! }
          .to change(subject, :processed_at)
          .from(nil)
          .to(Time.zone.now)
      end
    end
  end
end
