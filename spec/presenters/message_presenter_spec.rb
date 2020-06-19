RSpec.describe MessagePresenter do
  include UTMHelpers

  describe ".call" do
    around do |example|
      ClimateControl.modify(GOVUK_APP_DOMAIN: "gov.uk") { example.run }
    end

    it "returns a presenter message" do
      message = create(
        :message,
        title: "My title",
        body: "Some information\nfor a user",
      )

      expected = <<~MESSAGE
        My title

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end

    it "can link to the title" do
      message = create(
        :message,
        title: "My title",
        url: "/my-page",
        body: "Some information\nfor a user",
      )

      expected = <<~MESSAGE
        [My title](https://www.gov.uk/my-page?#{message_utm_params(message.id, 'immediate')})

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end

    it "copes with a path with a query string" do
      message = create(
        :message,
        title: "My title",
        url: "/my-page?my-query=this",
        body: "Some information\nfor a user",
      )

      expected = <<~MESSAGE
        [My title](https://www.gov.uk/my-page?my-query=this&#{message_utm_params(message.id, 'immediate')})

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end

    it "doesn't replace the host of an absolute URL" do
      message = create(
        :message,
        title: "My title",
        url: "https://other-government-service/test",
        body: "Some information\nfor a user",
      )

      expected = <<~MESSAGE
        [My title](https://other-government-service/test)

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end

    it "doesn't add Google Analytics params to a URL which already has this" do
      message = create(
        :message,
        title: "My title",
        url: "/test?utm_source=custom-source",
        body: "Some information\nfor a user",
      )

      expected = <<~MESSAGE
        [My title](https://www.gov.uk/test?utm_source=custom-source)

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end

    it "adds Google Analytics params to an absolute GOV.UK URL" do
      message = create(
        :message,
        title: "My title",
        url: "https://www.gov.uk/test",
        body: "Some information\nfor a user",
      )

      expected = <<~MESSAGE
        [My title](https://www.gov.uk/test?#{message_utm_params(message.id, 'immediate')})

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end
  end
end
