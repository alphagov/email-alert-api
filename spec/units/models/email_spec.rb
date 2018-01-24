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
  end

  describe "create_from_params!" do
    let(:content_change) { create(:content_change) }
    let(:subscriber) { double(address: "test@test.com", subscriptions: []) }

    let(:email) do
      Email.create_from_params!(
        title: "Title",
        description: "Description",
        change_note: "Change note",
        base_path: "/government/test",
        public_updated_at: Time.parse("1/1/2017"),
        content_change_id: content_change.id,
        subscriber: subscriber,
      )
    end

    it "sets subject" do
      expect(email.subject).to_not be_nil
    end

    it "sets body" do
      expect(email.body).to_not be_nil
    end
  end
end
