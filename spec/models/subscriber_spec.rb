RSpec.describe Subscriber, type: :model do
  context "validations" do
    subject { build(:subscriber) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    # this is not meant to be comprehensive, but it should be good enough to
    # spot potential problems with our validation
    %w(
      email@example.com
      firstname.lastname@example.com
      email@subdomain.example.com
      firstname+lastname@example.com
      email@123.123.123.123
      email@[123.123.123.123]
      email@[2001:0db8:85a3:0000:0000:8a2e:0370:7334]
      "email"@example.com
      1234567890@example.com
      email@example-one.com
      _______@example.com
      firstname-lastname@example.com
    ).each do |email_address|
      it "is valid for #{email_address}" do
        subject.address = email_address
        expect(subject).to be_valid
      end
    end

    it "is invalid for an empty string email address" do
      subject.address = ""
      expect(subject).to be_invalid

      subject.address = " "
      expect(subject).to be_invalid
    end

    it "is invalid for an email address which doesn't have an @" do
      subject.address = "not an email address"

      expect(subject).to be_invalid
    end

    it "is invalid for an email address which doesn't have a . in the domain" do
      subject.address = "me@localhost"

      expect(subject).to be_invalid
    end

    it "is invalid for an email address which has a domain starting with a ." do
      subject.address = "me@.invalid"

      expect(subject).to be_invalid
    end

    it "is invalid for an email address which contains a newline" do
      subject.address = "foo@bar.com\nfoo@baz.com"

      expect(subject).to be_invalid
    end

    it "is invalid for an email address which contains a space" do
      subject.address = "foo @ bar.com"

      expect(subject).to be_invalid
    end

    it "is invalid for multiple email addresses" do
      subject.address = "foo@bar.com,foo@baz.com"

      expect(subject).to be_invalid
    end

    it "is invalid if an email address is already taken" do
      create(:subscriber, address: "foo@bar.com")

      subject.address = "foo@bar.com"
      expect(subject).to be_invalid

      expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "is invalid if an email address is already taken but with a different case" do
      create(:subscriber, address: "FOO@BAR.com")

      subject.address = "foo@bar.com"
      expect(subject).to be_invalid

      expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "with a subscription" do
    subject { create(:subscriber) }

    before { create(:subscription, subscriber: subject) }

    it "can access the subscriber lists" do
      expect(subject.subscriber_lists.size).to eq(1)
    end

    it "cannot be deleted" do
      expect { subject.destroy }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe ".find_by_address" do
    let!(:subscriber) { create(:subscriber, address: "Test@example.com") }
    subject { described_class.find_by_address(address) }

    context "when address is a different case" do
      let(:address) { "TEST@EXAMPLE.COM" }
      it { is_expected.to eq subscriber }
    end

    context "when the address doesn't match" do
      let(:address) { "different@example.com" }
      it { is_expected.to be_nil }
    end
  end

  describe ".find_by_address!" do
    let!(:subscriber) { create(:subscriber, address: "Test@example.com") }
    subject(:find_address) { described_class.find_by_address!(address) }

    context "when address is a different case" do
      let(:address) { "TEST@EXAMPLE.COM" }
      it { is_expected.to eq subscriber }
    end

    context "when the address doesn't match" do
      let(:address) { "different@example.com" }

      it "raises an error" do
        expect { find_address }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".resilient_find_or_create" do
    context "when a subscriber already exists" do
      let!(:subscriber) { create(:subscriber) }

      it "fetches the subscriber" do
        expect(described_class.resilient_find_or_create(subscriber.address))
          .to eq(subscriber)
      end

      it "ignores any create fields" do
        user_uid = SecureRandom.uuid
        described_class.resilient_find_or_create(
          subscriber.address,
          singon_user_uid: user_uid,
        )

        expect(subscriber.reload.signon_user_uid).not_to eq(user_uid)
      end
    end

    context "when a subscriber does not exist" do
      let(:address) { "new-subscriber@example.com" }

      it "creates a new subscriber" do
        expect { described_class.resilient_find_or_create(address) }
          .to change { Subscriber.exists?(address:) }
          .to(true)
      end

      it "sets any specified create fields" do
        user_uid = SecureRandom.uuid
        subscriber = described_class.resilient_find_or_create(
          address,
          signon_user_uid: user_uid,
        )

        expect(subscriber.reload)
          .to have_attributes(address:, signon_user_uid: user_uid)
      end
    end

    context "when a subscriber is created after we fail to find the subscriber" do
      let!(:subscriber) { create(:subscriber) }

      it "retries one time before raising an error" do
        allow(described_class).to receive(:find_by_address).and_return(nil, subscriber)
        expect(described_class.resilient_find_or_create(subscriber.address))
          .to eq(subscriber)

        allow(described_class).to receive(:find_by_address).and_return(nil)
        expect { described_class.resilient_find_or_create(subscriber.address) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#active_subscriptions" do
    let(:subscriber) { create(:subscriber) }
    before do
      create(:subscription, subscriber:)
      create(:subscription, subscriber:)
      create(:subscription, :ended, subscriber:)
    end

    it "returns active subscriptions" do
      expect(subscriber.active_subscriptions.count).to eq 2
    end
  end

  describe "#ended_subscriptions" do
    let(:subscriber) { create(:subscriber) }
    before do
      create(:subscription, subscriber:)
      create(:subscription, subscriber:)
      create(:subscription, :ended, subscriber:)
    end

    it "returns ended subscriptions" do
      expect(subscriber.ended_subscriptions.count).to eq 1
    end
  end
end
