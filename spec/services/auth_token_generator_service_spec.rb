RSpec.describe AuthTokenGeneratorService do
  include TokenHelpers

  describe ".call" do
    it "can be decoded" do
      token = described_class.call("token")
      expect(decrypt_and_verify_token(token)).to eq("token")
    end

    it "expires in one week" do
      token = described_class.call("token")

      Timecop.freeze(6.days.from_now) do
        expect(decrypt_and_verify_token(token)).to_not be_nil
      end

      Timecop.freeze(1.week.from_now) do
        expect(decrypt_and_verify_token(token)).to be_nil
      end
    end
  end
end
