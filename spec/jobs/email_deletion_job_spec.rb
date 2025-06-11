RSpec.describe EmailDeletionJob do
  describe "#perform" do
    def perform
      described_class.new.perform
    end

    context "when there are no emails to delete" do
      before { create(:email) }

      it "doesn't change the number of Email records" do
        expect { perform }.not_to(change { Email.count })
      end
    end

    context "when there are emails to delete" do
      before { create(:deleteable_email) }

      it "deletes the Email records" do
        expect { perform }.to change { Email.count }.by(-1)
      end
    end
  end
end
