RSpec.describe AuthTokenGeneratorService do
  include TokenHelpers

  describe ".call" do
    it "can be decoded" do
      token = described_class.call("token")
      expect(decrypt_and_verify_token(token)).to eq("token")
    end

    it "expires in one week" do
      token = described_class.call("token")

      travel_to(6.days.from_now) do
        expect(decrypt_and_verify_token(token)).to_not be_nil
      end

      travel_to(8.days.from_now) do
        expect(decrypt_and_verify_token(token)).to be_nil
      end
    end
  end

  describe ".crypt" do
    it "caches the encryptor for performance" do
      expect(described_class.crypt).to be_a ActiveSupport::MessageEncryptor
      expect(described_class.crypt).to equal(described_class.crypt)
    end
  end
end
