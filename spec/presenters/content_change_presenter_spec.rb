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
        [Change title](http://www.dev.gov.uk/government/test-slug?#{utm_params(content_change.id, 'immediate')})

        Test description

        10:00am, 1 January 2018: Test change note
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
          [Change title](http://www.dev.gov.uk/government/test-slug?#{utm_params(content_change.id, 'immediate')})

          more markdown

          10:00am, 1 January 2018: Test change note markdown test (https://gov.uk)
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end

    context "when the content change has no description" do
      let(:content_change) {
        build(
          :content_change, description: "",
          public_updated_at: Time.parse("10:00 1/1/2018")
        )
      }

      it "doesn't leave an empty gap" do
        expected = <<~CONTENT_CHANGE
          [title](http://www.dev.gov.uk/government/base_path?#{utm_params(content_change.id, 'immediate')})

          10:00am, 1 January 2018: change note
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end

    context "when the content change has a footnote" do
      let(:content_change) {
        build(
          :content_change, footnote: "footnote",
          public_updated_at: Time.parse("10:00 1/1/2018")
        )
      }

      it "includes the footnote at the bottom" do
        expected = <<~CONTENT_CHANGE
          [title](http://www.dev.gov.uk/government/base_path?#{utm_params(content_change.id, 'immediate')})

          description

          10:00am, 1 January 2018: change note

          footnote
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end
  end
end
