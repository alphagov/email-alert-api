require "rails_helper"

RSpec.describe ContentChangePresenter do
  let(:content_change) {
    build(
      :content_change, title: "Change title",
      base_path: "/government/test-slug",
      change_note: "Test change note",
      description: "Test description",
      public_updated_at: Time.parse("10:00 1/1/2018")
    )
  }

  describe ".call" do
    it "returns a presenter content change" do
      expected = <<~CONTENT_CHANGE
        [Change title](http://www.dev.gov.uk/government/test-slug)

        Test description

        10:00am, 1 January 2018: Test change note
      CONTENT_CHANGE

      expect(described_class.call(content_change)).to eq(expected)
    end

    context "when the content change is travel advice" do
      let(:content_change) { create(:content_change, :travel_advice, public_updated_at: Time.parse("10:00 1/1/2018")) }

      it "doesn't include the description" do
        expected = <<~CONTENT_CHANGE
          [title](http://www.dev.gov.uk/government/base_path)

          10:00am, 1 January 2018: change note
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end

    context "when the content change is medical safety alert" do
      let(:content_change) { create(:content_change, :medical_safety_alert, public_updated_at: Time.parse("10:00 1/1/2018")) }

      it "includes the MHRA line" do
        expected = <<~CONTENT_CHANGE
          [title](http://www.dev.gov.uk/government/base_path)

          description

          10:00am, 1 January 2018: change note

          Do not reply to this email. To contact MHRA, email [email.support@mhra.gov.uk](mailto:email.support@mhra.gov.uk)
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end

    context "when content change contains markdown" do
      let(:content_change) {
        build(
          :content_change, title: "Change title",
          base_path: "/government/test-slug",
          change_note:  "#Test change note **markdown** [test](https://gov.uk)",
          description: "more _markdown_",
          public_updated_at: Time.parse("10:00 1/1/2018")
        )
      }

      it "strips markdown" do
        expected = <<~CONTENT_CHANGE
          [Change title](http://www.dev.gov.uk/government/test-slug)

          more markdown

          10:00am, 1 January 2018: Test change note markdown test (https://gov.uk)
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end
  end
end
