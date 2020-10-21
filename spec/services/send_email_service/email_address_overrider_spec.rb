RSpec.describe SendEmailService::EmailAddressOverrider do
  let(:config) { EmailAlertAPI.config.email_service }

  describe "#destination_address" do
    subject(:destination_address) do
      described_class.new(config).destination_address(address)
    end

    context "when an override address is set" do
      let(:config) { { email_address_override: "overriden@example.com" } }
      let(:address) { "original@example.com" }

      it "returns the overridden address" do
        expect(destination_address).to eq("overriden@example.com")
      end
    end

    context "when an override address is not set" do
      let(:address) { "original@example.com" }

      it "returns the original address" do
        expect(destination_address).to eq("original@example.com")
      end
    end

    context "when an override address is set and whitelist addresses are set" do
      let(:config) do
        {
          email_address_override: "overriden@example.com",
          email_address_override_whitelist: ["whitelist@example.com"],
        }
      end

      context "when the argument is a whitelist address" do
        let(:address) { "whitelist@example.com" }

        it "returns the whitelisted address" do
          expect(destination_address).to eq("whitelist@example.com")
        end
      end

      context "when the argument is not a whitelist address" do
        let(:address) { "original@example.com" }

        it "returns the overriden address" do
          expect(destination_address).to eq("overriden@example.com")
        end
      end
    end

    context "when an override address is set and whitelist addresses are set and only whitelist emails should be sent" do
      let(:config) do
        {
          email_address_override: "overriden@example.com",
          email_address_override_whitelist: ["whitelist@example.com"],
          email_address_override_whitelist_only: true,
        }
      end

      context "when the argument is a whitelist address" do
        let(:address) { "whitelist@example.com" }

        it "returns the whitelisted address" do
          expect(destination_address).to eq("whitelist@example.com")
        end
      end

      context "when the argument is not a whitelist address" do
        let(:address) { "original@example.com" }

        it "returns a nil address" do
          expect(destination_address).to be_nil
        end
      end
    end

    context "when an override address is not set and whitelist addresses are set" do
      let(:config) do
        { email_address_override_whitelist: ["whitelist@example.com"] }
      end

      let(:address) { "original@example.com" }

      it "returns the original address" do
        expect(destination_address).to eq("original@example.com")
      end
    end
  end
end
