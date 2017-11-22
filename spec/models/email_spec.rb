require 'rails_helper'

RSpec.describe Email do
  let(:content_change) { create(:content_change) }
  let(:email) do
    Email.create_from_params!(
      title: "Title",
      description: "Description",
      change_note: "Change note",
      base_path: "/government/test",
      public_updated_at: DateTime.parse("1/1/2017"),
      content_change_id: content_change.id,
      address: "test@example.com",
    )
  end

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
    let(:email_renderer) { double }

    before do
      allow(email_renderer).to receive(:subject).and_return("a subject")
      allow(email_renderer).to receive(:body).and_return("a body")
      allow(EmailRenderer).to receive(:new).and_return(email_renderer)
    end

    it "sets subject" do
      expect(email.subject).to eq("a subject")
    end

    it "sets body" do
      expect(email.body).to eq("a body")
    end
  end

  describe "mark_processed!" do
    it "sets processed_at" do
      Timecop.freeze do
        now = Time.now
        email.mark_processed!
        expect(email.processed_at).to eq(now)
      end
    end
  end
end
