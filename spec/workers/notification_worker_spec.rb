require "rails_helper"

RSpec.describe NotificationWorker do
  describe "#perform" do
    before do
      @gov_delivery = double(:gov_delivery, send_bulletin: nil)
      allow(Services).to receive(:gov_delivery).and_return(@gov_delivery)
      allow(Rails.logger).to receive(:info)
    end

    let(:notification_params) do
      {
        subject: "Test subject",
        body: "Test body copy",
        content_id: "111111-aaaaaa",
        public_updated_at: "2017-02-21T14:58:45+00:00",
        govuk_request_id: 'AAAAAA',
      }
    end

    def make_it_perform
      NotificationWorker.new.perform(notification_params)
    end

    context "given a subscriber list matched on tags" do
      before do
        create(:subscriber_list, gov_delivery_id: 'gov123', tags: { topics: ['foo/bar'] })
        notification_params.merge!(tags: { topics: ['foo/bar'] })
      end

      it "sends a bulletin with the correct IDs" do
        make_it_perform

        expect(@gov_delivery).to have_received(:send_bulletin)
          .with(
            ['gov123'],
            "Test subject",
            "Test body copy",
            {},
          )
      end

      it 'creates a delivery log record' do
        expect { make_it_perform }.to change { NotificationLog.count }.by(1)

        expect(NotificationLog.last).to have_attributes(
          govuk_request_id: 'AAAAAA',
          content_id: "111111-aaaaaa",
          public_updated_at: Time.parse("2017-02-21T14:58:45+00:00"),
          links: {},
          tags: { 'topics' => ['foo/bar'] },
          document_type: nil,
          email_document_supertype: nil,
          government_document_supertype: nil,
          gov_delivery_ids: ['gov123'],
        )
      end
    end

    context "given a subscriber list matched on both links and tags" do
      before do
        create(
          :subscriber_list,
          gov_delivery_id: 'gov123',
          tags:   { topics: ['foo/bar'] },
          links:  { topics: ['uuid'] },
        )
        notification_params.merge!(tag: { topics: ['foo/bar'] }, links: { topics: ['uuid'] })
      end

      it "sends a bulletin with the correct IDs" do
        make_it_perform

        expect(@gov_delivery).to have_received(:send_bulletin)
          .with(
            ['gov123'],
            "Test subject",
            "Test body copy",
            {},
          )
      end

      context "Logging of the notification creates an unexpected exception" do
        before do
          expect(NotificationLog).to receive(:create).and_raise(Exception)
        end

        it "the process ends without an exception" do
          expect { make_it_perform }.not_to raise_error
        end

        it "the bulletin is still sent" do
          make_it_perform

          expect(@gov_delivery).to have_received(:send_bulletin)
        end
      end
    end

    context "filtering on document_type" do
      context "when the optional document_type is set in the subscriber list" do
        before do
          create(:subscriber_list, document_type: 'travel-advice', tags: { topics: ['foo/bar'] })
          notification_params.merge!(tags: { topics: ['foo/bar'] })
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
          create(:subscriber_list, tags: { topics: ['foo/bar'] })
          notification_params.merge!(tags: { topics: ['foo/bar'] })
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
        create(:subscriber_list, email_document_supertype: 'publications', tags: {}, links: {})
        create(:subscriber_list, government_document_supertype: 'new-stories', tags: {}, links: {})
      end

      it "sends a bulletin when document_type matches" do
        notification_params[:document_type] = 'travel-advice'
        make_it_perform
        expect(@gov_delivery).to have_received(:send_bulletin)
      end

      it "sends a bulletin when email_document_supertype matches" do
        notification_params[:email_document_supertype] = 'publications'
        make_it_perform
        expect(@gov_delivery).to have_received(:send_bulletin)
      end

      it "sends a bulletin when government_document_supertype matches" do
        notification_params[:government_document_supertype] = 'new-stories'
        make_it_perform
        expect(@gov_delivery).to have_received(:send_bulletin)
      end

      it "does not send a bulletin when document_type does not match" do
        notification_params[:document_type] = 'not-travel-advice'
        make_it_perform
        expect(@gov_delivery).not_to have_received(:send_bulletin)
      end

      it "does not sends a bulletin when email_document_supertype does not match" do
        notification_params[:email_document_supertype] = 'not-publications'
        make_it_perform
        expect(@gov_delivery).not_to have_received(:send_bulletin)
      end

      it "does not sends a bulletin when government_document_supertype does not match" do
        notification_params[:government_document_supertype] = 'not-new-stories'
        make_it_perform
        expect(@gov_delivery).not_to have_received(:send_bulletin)
      end

      context "and the notification has some tags" do
        before do
          notification_params.merge!(tags: { countries: ['andorra'] })
        end

        it "sends a bulletin when document_type matches" do
          notification_params[:document_type] = 'travel-advice'
          make_it_perform
          expect(@gov_delivery).to have_received(:send_bulletin)
          expect(Rails.logger).to have_received(:info).with(/matched 1 list/)
        end

        it "does not send a bulletin when document_type does not match" do
          notification_params[:document_type] = 'not-travel-advice'
          make_it_perform
          expect(@gov_delivery).not_to have_received(:send_bulletin)
          expect(Rails.logger).not_to have_received(:info).with(/matched/)
        end

        context "and the notification matches another list on tags" do
          before do
            create(
              :subscriber_list,
              document_type: 'travel-advice',
              tags: { countries: ['andorra'] },
            )
          end

          it "sends a bulletin when document_type matches" do
            notification_params[:document_type] = 'travel-advice'
            make_it_perform

            expect(@gov_delivery).to have_received(:send_bulletin).once
            expect(Rails.logger).to have_received(:info).with(/matched 2 lists/)
          end

          it "does not send a bulletin when document_type does not match" do
            notification_params[:document_type] = 'not-travel-advice'
            make_it_perform
            expect(@gov_delivery).not_to have_received(:send_bulletin)
            expect(Rails.logger).not_to have_received(:info).with(/matched/)
          end
        end
      end
    end

    context "given the subscriber list has no subscribers - GovDelivery raises a GD-12004" do
      before do
        create(
          :subscriber_list,
          tags: { topics: ['foo/bar'] },
          links: {},
        )
        notification_params[:tags] = { topics: ['foo/bar'] }

        expect(@gov_delivery).to receive(:send_bulletin).and_raise(
          GovDelivery::Client::UnknownError,
          'GD-12004: To send a bulletin you must select at least one topic or category that has subscribers.'
        )
      end

      it "does not raise an error" do
        expect { make_it_perform }.not_to raise_error
      end
    end

    context "given GovDelivery raises an error other than GD-12004" do
      before do
        create(
          :subscriber_list,
          tags: { topics: ['foo/bar'] },
          links: {},
        )
        notification_params[:tags] = { topics: ['foo/bar'] }

        expect(@gov_delivery).to receive(:send_bulletin).and_raise(
          GovDelivery::Client::UnknownError,
          'GD-22222',
        )
      end

      it "raises an error" do
        expect { make_it_perform }.to raise_error(GovDelivery::Client::UnknownError)
      end
    end

    context "given a non-matching subscriber list" do
      before do
        create(
          :subscriber_list,
          gov_delivery_id: 'gov123',
          tags:   { topics: ['coal/environment'] },
          links:  { topics: ['uuid'] },
        )
        notification_params.merge!(tags: { topics: ['foo/bar'] }, links: { topics: ['uuid-888'] })
      end

      it "does not send a bulletin" do
        make_it_perform

        expect(@gov_delivery).to_not have_received(:send_bulletin)
      end

      it 'creates a notification log record' do
        expect { make_it_perform }.to change { NotificationLog.count }.by(1)

        expect(NotificationLog.last).to have_attributes(
          govuk_request_id: 'AAAAAA',
          content_id: "111111-aaaaaa",
          public_updated_at: Time.parse("2017-02-21T14:58:45+00:00"),
          links: { 'topics' => ['uuid-888'] },
          tags: { 'topics' => ['foo/bar'] },
          document_type: nil,
          gov_delivery_ids: [],
        )
      end
    end
  end
end
