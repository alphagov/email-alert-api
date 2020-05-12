RSpec.describe Clean::InvalidSubscribers do
  context "There are four subscribers" do
    before :each do
      @subscriber1 = FactoryBot.create(:subscriber, id: 1)
      @subscriber2 = FactoryBot.create(:subscriber, id: 2)
      @subscriber3 = FactoryBot.create(:subscriber, id: 3)
      @subscriber4 = FactoryBot.create(:subscriber, id: 4)
      @subscriber5 = FactoryBot.create(:subscriber, id: 5)
    end

    let(:sent_csv) do
      <<~CSV
        subscriber_id,count
        1,10
        2,5
        6,3
        7,4
      CSV
    end

    let(:failed_csv) do
      <<~CSV
        subscriber_id,count
        2,#{Clean::InvalidSubscribers::MIN_FAILURES}
        3,#{Clean::InvalidSubscribers::MIN_FAILURES}
        4,1
        5,#{Clean::InvalidSubscribers::MIN_FAILURES}
      CSV
    end

    before :each do
      Clean::InvalidSubscribers.new(sent_csv: StringIO.new(sent_csv),
                                    failed_csv: StringIO.new(failed_csv)).deactivate_subscribers(dry_run: false)
    end
    it "does not deactivate subscriber 1 - no failures" do
      expect(Subscriber.find(1)).to_not be_deactivated
    end
    it "does not deactivate subscriber 2 - there are successes" do
      expect(Subscriber.find(2)).to_not be_deactivated
    end
    it "deactivates subscriber 3 and 5 - at least 5 failures" do
      expect(Subscriber.find(3)).to be_deactivated
      expect(Subscriber.find(5)).to be_deactivated
    end
    it "does not deactivate subscriber 4 - not enough failures" do
      expect(Subscriber.find(4)).to_not be_deactivated
    end
  end

  context "the failed csv is bigger than the successes csv" do
    let(:sent_csv) do
      <<~CSV
        subscriber_id,count
        1,10
      CSV
    end

    let(:failed_csv) do
      <<~CSV
        subscriber_id,count
        2,5
        3,5
      CSV
    end
    it "reports there has been a mistake" do
      expect {
        Clean::InvalidSubscribers.new(sent_csv: StringIO.new(sent_csv),
                                      failed_csv: StringIO.new(failed_csv)).deactivate_subscribers
      }.to raise_error(RuntimeError, "Are the sent and failed csv files swapped?")
    end
  end
end
