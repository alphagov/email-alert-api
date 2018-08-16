RSpec.describe UnpublishEmailBuilder do
  describe ".call" do
    describe 'No emails sent' do
      it 'does not return any emails' do
        expect(described_class.call([])).to be_empty
      end
      it 'does not save and email objects' do
        expect { described_class.call([]) }.to_not(change { Email.count })
      end
    end

    describe 'One email sent' do
      let!(:subscriber) {
        create(
          :subscriber,
          address: "address@test.com",
          id: 123
)
      }
      let(:emails) {
        [
          {
            address: "address@test.com",
            subject: "subject_test",
            subscriber_id: 123,
          }
        ]
      }
      it 'Saves an email object' do
        expect { described_class.call(emails) }.to change { Email.count }.by(1)
      end
      describe 'return one email' do
        before :each do
          @imported_email = described_class.call(emails).first
        end
        it 'sets the subject' do
          expect(@imported_email.subject).to eq("subject_test")
        end
        it 'contains the subscriber id' do
          expect(@imported_email.subscriber_id).to eq(123)
        end
        it 'sets the status' do
          expect(@imported_email.status).to eq("pending")
        end
        it 'sets the addess' do
          expect(@imported_email.address).to eq("address@test.com")
        end

        it 'contains the body for the regular email' do
          expect(@imported_email.body).to include("Your subscription to ‘subject_test’ no longer exists, as a result you will no longer receive emails")
        end
      end
    end
  end
end
