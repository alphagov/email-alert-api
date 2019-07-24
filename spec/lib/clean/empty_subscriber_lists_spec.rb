RSpec.describe Clean::EmptySubscriberLists do
  let(:subject) { described_class.new }

  context "when there are empty lists" do
    let!(:list) { create(:subscriber_list) }

    describe "#lists" do
      it "returns one subscriber list" do
        expect(subject.lists.count).to eq(1)
        expect(subject.lists).to include(list)
      end
    end
  end

  context "when there are lists with subscribers" do
    let!(:list) { create(:subscriber_list_with_subscribers) }

    describe "#lists" do
      it "returns zero subscriber lists" do
        expect(subject.lists.count).to eq(0)
        expect(subject.lists).to_not include(list)
      end
    end
  end
end
