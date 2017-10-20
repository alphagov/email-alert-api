require "rails_helper"

RSpec.describe Subscriber, type: :model do
  context "validations" do
    subject { FactoryGirl.build(:subscriber) }

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

    it "is invalid for a nil email address" do
      subject.address = nil

      expect(subject).to be_invalid
    end

    it "is invalid for an email address which doesn't have an @" do
      subject.address = "not an email address"

      expect(subject).to be_invalid
    end

    it "is invalid if an email address is already taken" do
      FactoryGirl.create(:subscriber, address: "foo@bar.com")

      subject.address = "foo@bar.com"
      expect(subject).to be_invalid
    end
  end

  context "associations" do
    subject { FactoryGirl.create(:subscriber) }

    before do
      FactoryGirl.create(:subscription, subscriber: subject)
    end

    it "can access the subscriber lists" do
      expect(subject.subscriber_lists.size).to eq(1)
    end
  end
end
