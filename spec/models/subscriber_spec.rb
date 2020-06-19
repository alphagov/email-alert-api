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

    it "is valid for a nil email address when deactivated" do
      subject.deactivate!
      subject.address = nil
      expect(subject).to be_valid
    end

    it "is invalid for a nil email address when not deactivated" do
      subject.address = nil
      expect(subject).to be_invalid
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

      expect {
        subject.save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "is invalid if an email address is already taken but with a different case" do
      create(:subscriber, address: "FOO@BAR.com")

      subject.address = "foo@bar.com"
      expect(subject).to be_invalid

      expect {
        subject.save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "is valid to have more than one nullified subscriber" do
      create(:subscriber, :nullified)

      subject.deactivate!
      subject.nullify!
      expect(subject).to be_valid
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

  describe "#active_subscriptions" do
    let(:subscriber) { create(:subscriber) }
    before do
      create(:subscription, subscriber: subscriber)
      create(:subscription, subscriber: subscriber)
      create(:subscription, :ended, subscriber: subscriber)
    end

    it "returns active subscriptions" do
      expect(subscriber.active_subscriptions.count).to eq 2
    end
  end

  describe "#ended_subscriptions" do
    let(:subscriber) { create(:subscriber) }
    before do
      create(:subscription, subscriber: subscriber)
      create(:subscription, subscriber: subscriber)
      create(:subscription, :ended, subscriber: subscriber)
    end

    it "returns ended subscriptions" do
      expect(subscriber.ended_subscriptions.count).to eq 1
    end
  end
  describe "#activate!" do
    context "when activated" do
      subject(:subscriber) { create(:subscriber, :activated) }

      it "refuses to activate again" do
        expect { subscriber.activate! }.to raise_error(/Already activated/)
      end
    end

    context "when deactivated" do
      let(:deactivated_at) { Time.zone.parse("1/1/2017") }

      subject(:subscriber) { create(:subscriber, :deactivated, deactivated_at: deactivated_at) }

      it "activates the subscriber" do
        expect { subscriber.activate! }
          .to change { subscriber.reload.deactivated_at }
          .from(deactivated_at)
          .to(nil)

        expect(subscriber.reload.activated?).to be true
      end

      it "appears in the activated scope" do
        subscriber.activate!
        expect(Subscriber.activated.count).to eq(1)
      end

      it "doesn't appear in the deactivated scope" do
        subscriber.activate!
        expect(Subscriber.deactivated.count).to eq(0)
      end
    end

    context "when nullified" do
      subject(:subscriber) { create(:subscriber, :nullified) }

      it "refuses to activate" do
        expect { subscriber.activate! }.to raise_error(/Cannot activate/)
      end
    end
  end

  describe "#deactivate!" do
    context "when activated" do
      subject(:subscriber) { create(:subscriber, :activated) }

      it "deactivates the subscriber" do
        freeze_time do
          expect { subscriber.deactivate! }
            .to change { subscriber.reload.deactivated_at }
            .from(nil)
            .to(Time.zone.now)

          expect(subscriber.reload.deactivated?).to be true
        end
      end

      it "appears in the deactivated scope" do
        subscriber.deactivate!
        expect(Subscriber.deactivated.count).to eq(1)
      end

      it "doesn't appear in the activated scope" do
        subscriber.deactivate!
        expect(Subscriber.activated.count).to eq(0)
      end
    end

    context "when deactivated" do
      subject(:subscriber) { create(:subscriber, :deactivated) }

      it "refuses to deactivate" do
        expect { subscriber.deactivate! }.to raise_error(/Already deactivated/)
      end
    end
  end

  describe "#nullify!" do
    subject(:subscriber) { create(:subscriber, :deactivated, address: "foo@bar.com") }

    it "sets the address to nil and saves the record" do
      expect { subscriber.nullify! }
        .to change { subscriber.reload.address }
        .from("foo@bar.com")
        .to(nil)

      expect(subscriber.reload.nullified?).to be true
    end

    it "appears in the nullified scope" do
      subscriber.nullify!
      expect(Subscriber.nullified.count).to eq(1)
    end

    it "doesn't appear in the activated scope" do
      subscriber.nullify!
      expect(Subscriber.activated.count).to eq(0)
    end

    context "already nullified" do
      it "refuses to nullify again" do
        subscriber.nullify!

        expect { subscriber.nullify! }.to raise_error(/Already nullified/)
      end
    end
  end
end
