require "rails_helper"

RSpec.describe NotificationWorker do
  describe "#perform" do
    before do
      @gov_delivery = double(:gov_delivery, send_bulletin: nil)
      allow(Services).to receive(:gov_delivery).and_return(@gov_delivery)
    end

    let(:notification_params) do
      { subject: "Test subject", body: "Test body copy" }
    end

    def make_it_perform
      NotificationWorker.new.perform(notification_params)
    end

    context "given a subscriber list matched on tags" do
      before do
        create(:subscriber_list, gov_delivery_id: 'gov123', tags: {topics: ['foo/bar']})
        notification_params.merge!(tags: {topics: ['foo/bar']})
      end

      it "sends a bulletin with the correct IDs" do
        make_it_perform

        expect(@gov_delivery).to have_received(:send_bulletin)
          .with(
            ['gov123'],
            "Test subject",
            "Test body copy",
            {}
          )
      end
    end

    context "given a subscriber list matched on both links and tags" do
      before do
        create(
          :subscriber_list,
          gov_delivery_id: 'gov123',
          tags:   {topics: ['foo/bar']},
          links:  {topics: ['uuid']}
        )
        notification_params.merge!(tag: {topics: ['foo/bar']}, links: {topics: ['uuid']})
      end

      it "sends a bulletin with the correct IDs" do
        make_it_perform

        expect(@gov_delivery).to have_received(:send_bulletin)
          .with(
            ['gov123'],
            "Test subject",
            "Test body copy",
            {}
          )
      end
    end

    context "filtering on document_type" do
      context "when the optional document_type is set in the subscriber list" do
        before do
          create(:subscriber_list, document_type: 'travel-advice', tags: {topics: ['foo/bar']})
          notification_params.merge!(tags: {topics: ['foo/bar']})
        end

        it "sends a bulletin when document_type matches" do
          notification_params[:document_type] = 'travel-advice'
          make_it_perform
          expect(@gov_delivery).to have_received(:send_bulletin)
        end

        it "does not send a bulletin when document_type does not match" do
          notification_params[:document_type] = 'not-travel-advice'
          make_it_perform
          expect(@gov_delivery).not_to have_received(:send_bulletin)
        end

        it "does not send a bulletin when content item has no document_type" do
          make_it_perform
          expect(@gov_delivery).not_to have_received(:send_bulletin)
        end
      end

      context "when the optional document_type is absent from the subscriber list" do
        before do
          create(:subscriber_list, tags: {topics: ['foo/bar']})
          notification_params.merge!(tags: {topics: ['foo/bar']})
        end

        it "sends a bulletin when content item has a document_type" do
          notification_params[:document_type] = 'travel-advice'
          make_it_perform
          expect(@gov_delivery).to have_received(:send_bulletin)
        end

        it "send a bulletin when content item has no document_type" do
          make_it_perform
          expect(@gov_delivery).to have_received(:send_bulletin)
        end
      end
    end

    context "when the subscriber list has no tags or links" do
      before do
        create(:subscriber_list, document_type: 'travel-advice', tags: {}, links: {})
      end

      it "sends a bulletin when document_type matches" do
        notification_params[:document_type] = 'travel-advice'
        make_it_perform
        expect(@gov_delivery).to have_received(:send_bulletin)
      end

      it "does not send a bulletin when document_type does not match" do
        notification_params[:document_type] = 'not-travel-advice'
        make_it_perform
        expect(@gov_delivery).not_to have_received(:send_bulletin)
      end
    end

    context "given a non-matching subscriber list" do
      before do
        create(
          :subscriber_list,
          gov_delivery_id: 'gov123',
          tags:   {topics: ['coal/environment']},
          links:  {topics: ['uuid']}
        )
        notification_params.merge!(tag: {topics: ['foo/bar']}, links: {topics: ['uuid-888']})
      end

      it "does not send a bulletin" do
        make_it_perform

        expect(@gov_delivery).to_not have_received(:send_bulletin)
      end
    end
  end
end
