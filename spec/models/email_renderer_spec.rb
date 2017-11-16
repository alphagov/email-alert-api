require 'rails_helper'

RSpec.describe EmailRenderer do
  let(:params) do
    {
      title: "Title",
      public_updated_at: DateTime.parse("1/1/2017"),
      description: "Description",
      change_note: "Change note",
      base_path: "/base_path",
    }
  end

  subject { EmailRenderer.new(params: params) }

  describe "subject" do
    it "should match the expected title" do
      expect(subject.subject).to eq("GOV.UK Update - #{params[:title]}")
    end
  end

  describe "body" do
    it "should match the expected content" do
      expect(subject.body).to eq(
        <<~BODY
          Change note: Description.

          http://www.dev.gov.uk/base_path
          Updated on 12:00 am, 1 January 2017

          Unsubscribe from Title - http://www.dev.gov.uk/email/token/unsubscribe
        BODY
      )
    end
  end
end
