RSpec.describe AuthEmailBuilder do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }
    let(:destination) { "/destination" }
    let(:token) { "secret" }

    subject(:call) do
      described_class.call(
        subscriber: subscriber,
        destination: destination,
        token: token,
      )
    end

    it { is_expected.to be_instance_of(Email) }

    it "creates an email" do
      expect { call }.to change(Email, :count).by(1)
    end

    it "has a link to authenticate" do
      link = "http://www.dev.gov.uk/destination?token=secret"
      email = call
      expect(email.body).to include(link)
    end
  end
end
