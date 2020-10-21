RSpec.describe EmailDeletionWorker do
  describe "#perform" do
    def perform
      described_class.new.perform
    end

    context "when there are no emails to delete" do
      before do
        create(:email)
        create(:archived_email)
      end
      it "doesn't change the number of Email records" do
        expect { perform }.not_to(change { Email.count })
      end
    end

    context "when there are emails to delete" do
      let!(:emails) { 3.times.map { create(:deleteable_email) } }

      it "deletes the Email records" do
        expect { perform }.to change { Email.count }.by(-3)
      end
    end
  end
end
