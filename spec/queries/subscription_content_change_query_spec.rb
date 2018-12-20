RSpec.describe SubscriptionContentChangeQuery do
  let(:subscriber) do
    create(:subscriber)
  end

  let(:ends_at) { Time.parse("2017-01-02 08:00") }

  let(:digest_run) do
    create(:digest_run, :daily, date: ends_at)
  end

  let(:starts_at) { digest_run.starts_at }

  subject { described_class.call(subscriber: subscriber, digest_run: digest_run) }

  context "with one subscription" do
    let(:subscriber_list) do
      create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } })
    end

    let!(:subscription) do
      create(:subscription, :daily, subscriber_list: subscriber_list, subscriber: subscriber)
    end

    def create_and_match_content_change(created_at: starts_at, title: nil)
      content_change = create(
        :content_change,
        tags: { topics: { any: ["oil-and-gas/licensing"] } },
        created_at: created_at,
      )
      content_change.update!(title: title) if title
      create(
        :matched_content_change,
        content_change: content_change,
        subscriber_list: subscriber_list,
      )
    end

    describe ".call" do
      context "with a mismatched frequency and digest range" do
        before do
          subscription.update_attributes(frequency: Frequency::WEEKLY)
          create_and_match_content_change
        end

        it "does not return a result" do
          expect(subject).to be_empty
        end
      end

      context "with a matched content change" do
        before do
          create_and_match_content_change
        end

        it "returns one result" do
          expect(subject.first.content_changes.count).to eq(1)
        end

        context "with an ended subscription" do
          before do
            subscription.end(reason: :unsubscribed)
          end

          it "returns no results" do
            expect(subject.count).to eq(0)
          end
        end
      end

      context "with two matched content changes" do
        before do
          create_and_match_content_change(title: "Z")
          create_and_match_content_change(title: "A")
        end

        it "returns two results correctly ordered" do
          expect(subject.first.content_changes.count).to eq(2)
          expect(subject.first.content_changes.first.title).to eq("A")
          expect(subject.first.content_changes.second.title).to eq("Z")
        end
      end

      context "with a matched content change that's out of date" do
        before do
          create_and_match_content_change(created_at: ends_at)
        end

        it "returns no results" do
          expect(subject.count).to eq(0)
        end
      end

      context "with no matched content changes" do
        before do
          create(:content_change)
        end

        it "returns no results" do
          expect(subject.count).to eq(0)
        end
      end
    end
  end

  context "with two subscriptions" do
    let(:subscriber_list_1) do
      create(:subscriber_list, title: "list-1", tags: { topics: { any: ["oil-and-gas/licensing"] } })
    end

    let(:subscriber_list_2) do
      create(:subscriber_list, title: "list-2", tags: { topics: { any: ["oil-and-gas/drilling"] } })
    end

    let!(:subscription_2) do
      create(:subscription, :daily, id: "b8c3fd84-5f00-460d-a812-edb628f28c8f", subscriber_list: subscriber_list_2, subscriber: subscriber)
    end

    let!(:subscription_1) do
      create(:subscription, :daily, id: "b0f887f1-20b1-4386-881d-f909c98c373b", subscriber_list: subscriber_list_1, subscriber: subscriber)
    end

    let(:content_change_1) do
      create(
        :content_change,
        id: "d5ee8e1a-72c1-4525-94f0-23d58af8a6c5",
        tags: { topics: { any: ["oil-and-gas/licensing"] } },
        created_at: starts_at,
      )
    end

    let(:content_change_2) do
      create(
        :content_change,
        id: "70ac31fa-505e-4060-b7bb-bfa15028cc99",
        tags: { topics: { any: ["oil-and-gas/drilling"] } },
        created_at: starts_at,
      )
    end

    before do
      create(
        :matched_content_change,
        content_change: content_change_1,
        subscriber_list: subscriber_list_1,
      )

      create(
        :matched_content_change,
        content_change: content_change_2,
        subscriber_list: subscriber_list_2,
      )

      create(
        :matched_content_change,
        content_change: content_change_1,
        subscriber_list: subscriber_list_2,
      )
    end

    it "returns correctly ordered" do
      expect(subject.first.subscription_id).to eq("b0f887f1-20b1-4386-881d-f909c98c373b")
      expect(subject.first.subscriber_list_title).to eq("list-1")
      expect(subject.first.content_changes.first.id).to eq("d5ee8e1a-72c1-4525-94f0-23d58af8a6c5")

      expect(subject.second.subscription_id).to eq("b8c3fd84-5f00-460d-a812-edb628f28c8f")
      expect(subject.second.subscriber_list_title).to eq("list-2")
      expect(subject.second.content_changes.first.id).to eq("70ac31fa-505e-4060-b7bb-bfa15028cc99")
    end

    it "returns only two changes" do
      expect(subject.length).to eq(2)
    end
  end
end
