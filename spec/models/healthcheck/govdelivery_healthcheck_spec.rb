RSpec.describe Healthcheck::GovdeliveryHealthcheck do
  let(:url) { "http://govdelivery-api.example.com/api/account/UKGOVUK/categories.xml" }
  let(:headers) { { "Authorization" => "Basic #{HTTP_AUTH_CREDENTIALS}" } }
  let(:status) { 200 }

  before do
    stub_request(:get, url).with(headers: headers).to_return(status: status)
  end

  context "when a ping succeeds" do
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when a ping fails" do
    let(:status) { 410 }
    specify { expect(subject.status).to eq(:critical) }
  end

  it "returns the ping status in details" do
    expect(subject.details).to eq(ping_status: status)
  end
end
