RSpec.describe Message do
  describe "path" do
    it "is valid when path is nil" do
      expect(build(:message, path: nil)).to be_valid
    end

    it "is valid when path is an absolute path" do
      expect(build(:message, path: "/test")).to be_valid
    end

    it "is valid when path is an absolute URI" do
      expect(build(:message, path: "https://example.com/test")).to be_invalid
    end
  end

  describe "#mark_processed!" do
    it "sets processed_at" do
      Timecop.freeze do
        message = create(:message)
        expect { message.mark_processed! }
          .to change(message, :processed_at)
          .from(nil)
          .to(Time.now)
      end
    end
  end
end
