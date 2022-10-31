RSpec.describe SubscriptionContent do
  describe ".populate_for_content" do
    around { |example| freeze_time { example.run } }

    let(:email) { create(:email) }
    let(:subscriptions) { create_list(:subscription, 2) }
    let(:records) do
      subscriptions.map { |s| { subscription_id: s.id, email_id: email.id } }
    end

    it "adds records when given a content change" do
      content_change = create(:content_change)
      expect { described_class.populate_for_content(content_change, records) }
        .to change { SubscriptionContent.count }.by(2)

      expect(SubscriptionContent.last)
        .to have_attributes(subscription_id: subscriptions.last.id,
                            email_id: email.id,
                            content_change_id: content_change.id,
                            message_id: nil,
                            created_at: Time.zone.now,
                            updated_at: Time.zone.now)
    end

    it "adds records when given a message" do
      message = create(:message)
      expect { described_class.populate_for_content(message, records) }
        .to change { SubscriptionContent.count }.by(2)

      expect(SubscriptionContent.last)
        .to have_attributes(subscription_id: subscriptions.last.id,
                            email_id: email.id,
                            content_change_id: nil,
                            message_id: message.id,
                            created_at: Time.zone.now,
                            updated_at: Time.zone.now)
    end

    it "raise an ArgumentError when given a different object" do
      expect { described_class.populate_for_content({}, records) }
        .to raise_error(ArgumentError, "Expected Hash to be a ContentChange or a Message")
    end

    it "raises an error when records already exist" do
      content_change = create(:content_change)
      create(:subscription_content,
             content_change:,
             email:,
             subscription: subscriptions.last)

      expect { described_class.populate_for_content(content_change, records) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
