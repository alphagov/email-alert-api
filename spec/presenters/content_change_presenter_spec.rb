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

        Test change note: Test description

        Updated at 10:00 am on 1 January 2018
      CONTENT_CHANGE

      expect(described_class.call(content_change)).to eq(expected)
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

          Test change note markdown test (https://gov.uk): more markdown

          Updated at 10:00 am on 1 January 2018
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end
  end
end
