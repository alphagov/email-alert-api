require 'rails_helper'

RSpec.describe Email do
  describe "validations" do
    it "requires subject" do
      subject.valid?
      expect(subject.errors[:subject]).not_to be_empty
    end

    it "requires body" do
      subject.valid?
      expect(subject.errors[:body]).not_to be_empty
    end

    it "requires a notification" do
      subject.valid?
      expect(subject.errors[:notification]).not_to be_empty
    end
  end

  describe "create_from_params!" do
    let(:notification) {
      create(:notification)
    }

    let(:email) {
      Email.create_from_params!(
        title: "Title",
        description: "Description",
        change_note: "Change note",
        base_path: "/government/test",
        public_updated_at: DateTime.parse("1/1/2017"),
        notification_id: notification.id,
      )
    }

    it "sets subject" do
      expect(email.subject).to eq("Title")
    end

    it "sets body" do
      expect(email.body).to eq(
        <<~BODY
          description: Description
          change_note: Change note
          base_path: /government/test
          updated: 00:00 1 January 2017
        BODY
      )
    end
  end
end
