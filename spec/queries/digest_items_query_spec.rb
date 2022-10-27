RSpec.describe DigestItemsQuery do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }
    let(:ends_at) { Time.zone.parse("2017-01-02 08:00") }
    let(:digest_run) { create(:digest_run, :daily, date: ends_at) }

    subject(:results) { described_class.call(subscriber, digest_run) }

    context "when there are no results" do
      it { is_expected.to be_empty }
    end

    context "with an active matching subscription" do
      let(:subscriber_list) { create(:subscriber_list) }
      let!(:subscription) do
        create(
          :subscription,
          :daily,
          subscriber_list:,
          subscriber:,
        )
      end

      it "returns the content changes and messages" do
        content_change = create(
          :content_change,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at,
        )
        message = create(
          :message,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at,
        )

        expect(results.count).to eq(1)
        expect(results.first.to_h)
          .to match(
            subscription:,
            content: [content_change, message],
          )
      end

      it "excludes overridden-immediate messages" do
        create(
          :message,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at,
          override_subscription_frequency_to_immediate: true,
        )

        message = create(
          :message,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at,
        )

        expect(results.count).to eq(1)
        expect(results.first.to_h)
          .to match(
            subscription:,
            content: [message],
          )
      end

      it "returns the content ordered by created_at time" do
        content_change1 = create(
          :content_change,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at,
        )
        content_change2 = create(
          :content_change,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at + 20.minutes,
        )
        message1 = create(
          :message,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at + 25.minutes,
        )
        message2 = create(
          :message,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at + 10.minutes,
        )
        expect(results.first.content)
          .to match([content_change1, message2, content_change2, message1])
      end

      it "returns only one content change if there are multiple with same content_id" do
        content_id = SecureRandom.uuid
        create(
          :content_change,
          :matched,
          content_id:,
          subscriber_list:,
          created_at: digest_run.starts_at,
        )
        create(
          :content_change,
          :matched,
          content_id:,
          subscriber_list:,
          created_at: digest_run.starts_at + 20.minutes,
        )

        expect(results.first.content.count).to eq(1)
      end
    end

    context "with multiple subscriber lists" do
      let(:subscriber_list1) { create(:subscriber_list, title: "Subscriber List A") }
      let(:subscriber_list2) { create(:subscriber_list, title: "Subscriber List B", url: "/example") }

      let!(:subscription1) do
        create(
          :subscription,
          :daily,
          subscriber_list: subscriber_list1,
          subscriber:,
        )
      end

      let!(:subscription2) do
        create(
          :subscription,
          :daily,
          subscriber_list: subscriber_list2,
          subscriber:,
        )
      end

      it "returns each subscriber list ordered by title" do
        content_change1 = create(
          :content_change,
          :matched,
          subscriber_list: subscriber_list1,
          created_at: digest_run.starts_at,
        )

        content_change2 = create(
          :content_change,
          :matched,
          subscriber_list: subscriber_list2,
          created_at: digest_run.starts_at,
        )

        expect(results.count).to eq(2)
        expect(results.first.to_h)
          .to match(
            subscription: subscription1,
            content: [content_change1],
          )

        expect(results.last.to_h)
          .to match(
            subscription: subscription2,
            content: [content_change2],
          )
      end

      it "includes a content item uniquely per list" do
        content_id = SecureRandom.uuid

        content_change1 = create(
          :content_change, :matched,
          content_id:,
          subscriber_list: subscriber_list1,
          created_at: digest_run.starts_at + 1.hour
        )

        create(
          :content_change, :matched,
          content_id:,
          subscriber_list: subscriber_list1,
          created_at: digest_run.starts_at
        )

        content_change3 = create(
          :content_change, :matched,
          content_id:,
          subscriber_list: subscriber_list2,
          created_at: digest_run.starts_at + 1.hour
        )

        create(
          :content_change, :matched,
          content_id:,
          subscriber_list: subscriber_list2,
          created_at: digest_run.starts_at
        )

        expect(results.count).to eq(2)
        expected_results = [
          [subscription1, [content_change1]],
          [subscription2, [content_change3]],
        ]

        expected_results.each.with_index do |(subscription, changes), index|
          expect(results[index].to_h)
            .to match(
              subscription:,
              content: changes,
            )
        end
      end

      it "returns a message only once if it's in two lists" do
        message = create(:message, created_at: digest_run.starts_at)
        create(:matched_message, message:, subscriber_list: subscriber_list1)
        create(:matched_message, message:, subscriber_list: subscriber_list2)

        expect(results.count).to eq(1)
        expect(results.first.to_h)
          .to match(
            subscription: subscription1,
            content: [message],
          )
      end
    end

    context "with an inactive matching subscription" do
      let(:subscriber_list) { create(:subscriber_list) }
      let!(:subscription) do
        create(
          :subscription,
          :daily,
          :ended,
          subscriber_list:,
          subscriber:,
        )
      end

      before do
        create(
          :content_change,
          :matched,
          subscriber_list:,
          created_at: digest_run.starts_at,
        )
      end

      it { is_expected.to be_empty }
    end
  end
end
