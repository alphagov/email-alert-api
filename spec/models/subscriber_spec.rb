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

    it "is valid for a nil email address" do
      subject.address = nil
      expect(subject).to be_valid
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

    it "is valid to have more than one nil email address" do
      create(:subscriber, address: nil)

      subject.address = nil
      expect(subject).to be_valid
    end
  end

  context "with a subscriber list" do
    subject { create(:subscriber) }

    before { create(:subscription, subscriber: subject) }

    it "can access the subscriber lists" do
      expect(subject.subscriber_lists.size).to eq(1)
    end

    it "can be deleted and won't delete the subscriber list" do
      expect { subject.destroy }.not_to raise_error
      expect(SubscriberList.all.size).to eq(1)
    end
  end

  describe "#nullify_address!" do
    it "sets the address to nil and saves the record" do
      subscriber = create(:subscriber, address: "foo@bar.com")

      expect { subscriber.nullify_address! }
        .to change { subscriber.reload.address }
        .from("foo@bar.com")
        .to(nil)
    end
  end
end
