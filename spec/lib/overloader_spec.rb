RSpec.describe Overloader do
  let(:list_1) { create :subscriber_list }
  let(:list_2) { create :subscriber_list }

  before do
    list_1.subscriptions << create_list(:subscription, 2)
    list_2.subscriptions << create_list(:subscription, 1)
    allow($stdout).to receive(:puts)
  end

  describe "#with_big_lists" do
    it "creates a fake content change" do
      expect { described_class.new(1).with_big_lists }
        .to change { ContentChange.count }.by 1
    end

    it "generates fake matches for the change" do
      expect { described_class.new(1).with_big_lists }
        .to change { MatchedContentChange.count }.by 1
    end

    it "kicks off a job to process the matches" do
      expect(ProcessContentChangeWorker).to receive(:perform_async)

      described_class.new(1).with_big_lists
    end

    it "prefers lists with more subscribers" do
      described_class.new(1).with_big_lists
      expect(list_1.matched_content_changes.count).to eq 1
    end

    it "loops to meet the required email volume" do
      expect { described_class.new(5).with_big_lists }
        .to change { ContentChange.count }.by(2)
        .and change { MatchedContentChange.count }.by 3
    end
  end

  describe "#with_small_lists" do
    it "prefers lists with more subscribers" do
      described_class.new(1).with_small_lists
      expect(list_2.matched_content_changes.count).to eq 1
    end

    it "loops to meet the required email volume" do
      expect { described_class.new(5).with_small_lists }
        .to change { ContentChange.count }.by(2)
        .and change { MatchedContentChange.count }.by 4
    end
  end
end
