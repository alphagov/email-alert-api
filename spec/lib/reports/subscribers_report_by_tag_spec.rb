RSpec.describe Reports::SubscribersReportByTag do
  describe "#call" do
    it "returns all brexit lists that contain the given criteria" do
      message = "There are 2 brexit related subscriptions\n1 active subscriptions for subscribers with the tag: eu-uk-funding\n"
      expect { described_class.new.call("eu-uk-funding", "brexit_subscribers_by_tag_fixture.csv") }.to output(message).to_stdout
    end
  end
end
