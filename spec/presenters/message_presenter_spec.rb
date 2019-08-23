require "rails_helper"

RSpec.describe MessagePresenter do
  describe ".call" do
    it "returns a presenter message" do
      message = create(:message,
                       title: "My title",
                       body: "Some information\nfor a user")

      expected = <<~MESSAGE
        My title

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end

    it "can link to the title" do
      message = create(:message,
                       title: "My title",
                       url: "/my-page",
                       body: "Some information\nfor a user")

      expected = <<~MESSAGE
        [My title](http://www.dev.gov.uk/my-page?#{message_utm_params(message.id, 'immediate')})

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end

    it "copes with a path with a query string" do
      message = create(:message,
                       title: "My title",
                       url: "/my-page?my-query=this",
                       body: "Some information\nfor a user")

      expected = <<~MESSAGE
        [My title](http://www.dev.gov.uk/my-page?my-query=this&#{message_utm_params(message.id, 'immediate')})

        Some information
        for a user
      MESSAGE

      expect(described_class.call(message)).to eq(expected)
    end
  end
end
