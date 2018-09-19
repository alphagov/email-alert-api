RSpec.describe UnpublishingReport do
  before do
    create(:subscription, :unpublished, ended_at: '2018-08-29 13:04:03')
  end

  context 'generates report' do
    it "generates report if there has been unpublishing within time frame" do
      expect { described_class.call('2018/08/28', '2018/08/30') }.to output(
        "Unpublishing activity between 2018-08-28 00:00:00 +0000 and 2018-08-30 00:00:00 +0000\n'#{SubscriberList.last.title}' has been unpublished ending 1 subscriptions\n"
      ).to_stdout
    end

    it "doesn't generate any results as nothing has been unpublished in the time frame" do
      expect { described_class.call('2018/08/10', '2018/08/11') }.to output(
        "Unpublishing activity between 2018-08-10 00:00:00 +0000 and 2018-08-11 00:00:00 +0000\n"
      ).to_stdout
    end
  end
end
