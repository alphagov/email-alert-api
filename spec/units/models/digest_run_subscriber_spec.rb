require "rails_helper"

RSpec.describe DigestRunSubscriber do
  subject { build(:digest_run_subscriber) }

  describe "mark_complete!" do
    it "sets completed_at to Time.now" do
      Timecop.freeze do
        subject.mark_complete!
        expect(subject.completed_at).to eq(Time.now)
      end
    end
  end
end
