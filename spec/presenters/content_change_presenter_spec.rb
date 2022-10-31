RSpec.describe ContentChangePresenter do
  let(:subscriber_list) { create(:subscriber_list) }
  let(:subscription) { create(:subscription, subscriber_list:) }

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

  let(:result) do
    described_class.call(content_change, subscription)
  end

  before do
    allow(PublicUrls).to receive(:url_for)
      .with(
        base_path: content_change.base_path,
        utm_source: content_change.id,
        utm_content: subscription.frequency,
        utm_campaign: "govuk-notifications-topic",
      )
      .and_return("public_url")

    allow(PublicUrls).to receive(:url_for)
      .with(
        base_path: content_change.base_path,
        utm_source: content_change.id,
        utm_content: subscription.frequency,
        utm_campaign: "govuk-notifications-single-page",
      )
      .and_return("single_page_url")
  end

  describe ".call" do
    it "returns a presenter content change" do
      expected = <<~CONTENT_CHANGE
        # [Change title](public_url)

        Page summary:
        Test description

        Change made:
        Test change note

        Time updated:
        11:00am, 28 March 2018
      CONTENT_CHANGE

      expect(result).to eq(expected.strip)
    end

    context "when subscriber list is for a content id" do
      let(:subscriber_list) { create(:subscriber_list, content_id: SecureRandom.uuid) }

      it "generates a url with utm_campaign=govuk-notifications-single-page" do
        expected = <<~CONTENT_CHANGE
          # [Change title](single_page_url)

          Page summary:
          Test description

          Change made:
          Test change note

          Time updated:
          11:00am, 28 March 2018
        CONTENT_CHANGE

        expect(result).to eq(expected.strip)
      end
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
          # [Change title](public_url)

          Page summary:
          more markdown

          Change made:
          Test change note markdown test (https://gov.uk)

          Time updated:
          10:30am, 28 March 2018
        CONTENT_CHANGE

        expect(result).to eq(expected.strip)
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
          # [title](public_url)

          Change made:
          change note

          Time updated:
          10:00am, 1 January 2018
        CONTENT_CHANGE

        expect(result).to eq(expected.strip)
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
          # [title](public_url)

          Page summary:
          description

          Change made:
          change note

          Time updated:
          10:00am, 1 January 2018

          footnote
        CONTENT_CHANGE

        expect(result).to eq(expected.strip)
      end
    end
  end
end
