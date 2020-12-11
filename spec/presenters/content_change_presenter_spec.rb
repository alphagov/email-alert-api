RSpec.describe ContentChangePresenter do
  include UTMHelpers

  let(:content_change) do
    build(
      :content_change,
      title: "Change title",
      base_path: "/government/test-slug",
      change_note: "Test change note",
      description: "Test description",
      public_updated_at: Time.zone.parse("2018-03-28 10:00:00 UTC"),
    )
  end

  describe ".call" do
    it "returns a presenter content change" do
      expected = <<~CONTENT_CHANGE
        # [Change title](http://www.dev.gov.uk/government/test-slug?#{utm_params(content_change.id, 'immediate')})

        Page summary:
        Test description

        Change made:
        Test change note

        Time updated:
        11:00am, 28 March 2018
      CONTENT_CHANGE

      expect(described_class.call(content_change)).to eq(expected)
    end

    context "when content change contains markdown" do
      let(:content_change) do
        build(
          :content_change,
          title: "Change title",
          base_path: "/government/test-slug",
          change_note: "#Test change note **markdown** [test](https://gov.uk)",
          description: "more _markdown_",
          public_updated_at: Time.zone.parse("2018-03-28 09:30:00 UTC"),
        )
      end

      it "strips markdown" do
        expected = <<~CONTENT_CHANGE
          # [Change title](http://www.dev.gov.uk/government/test-slug?#{utm_params(content_change.id, 'immediate')})

          Page summary:
          more markdown

          Change made:
          Test change note markdown test (https://gov.uk)

          Time updated:
          10:30am, 28 March 2018
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end

    context "when the content change has no description" do
      let(:content_change) do
        build(
          :content_change,
          description: "",
          public_updated_at: Time.zone.parse("10:00 1/1/2018"),
        )
      end

      it "doesn't leave an empty gap" do
        expected = <<~CONTENT_CHANGE
          # [title](http://www.dev.gov.uk/government/base_path?#{utm_params(content_change.id, 'immediate')})

          Change made:
          change note

          Time updated:
          10:00am, 1 January 2018
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end

    context "when the content change has a footnote" do
      let(:content_change) do
        build(
          :content_change,
          footnote: "footnote",
          public_updated_at: Time.zone.parse("10:00 1/1/2018"),
        )
      end

      it "includes the footnote at the bottom" do
        expected = <<~CONTENT_CHANGE
          # [title](http://www.dev.gov.uk/government/base_path?#{utm_params(content_change.id, 'immediate')})

          Page summary:
          description

          Change made:
          change note

          Time updated:
          10:00am, 1 January 2018

          footnote
        CONTENT_CHANGE

        expect(described_class.call(content_change)).to eq(expected)
      end
    end
  end
end
