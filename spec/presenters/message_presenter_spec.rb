RSpec.describe MessagePresenter do
  describe ".call" do
    around do |example|
      ClimateControl.modify(GOVUK_APP_DOMAIN: "gov.uk") { example.run }
    end

    it "returns a presenter message" do
      message = create(
        :message,
        body: "Some information\nfor a user",
      )

      expected = <<~MESSAGE
        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end
  end
end
