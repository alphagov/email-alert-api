RSpec.describe "Healthcheck", type: :request do
  context "when the healthchecks pass" do
    it "returns a status of 'ok'" do
      get "/healthcheck"
      expect(data.fetch(:status)).to eq("ok")
    end
  end

  context "when one of the healthchecks is warning" do
    before do
      allow_any_instance_of(Healthcheck::QueueSizeHealthcheck)
        .to receive(:queues)
        .and_return(default: 80000)
    end

    it "returns a status of 'warning'" do
      get "/healthcheck"
      expect(data.fetch(:status)).to eq("warning")
    end
  end

  context "when one of the healthchecks is critical" do
    before do
      allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
    end

    it "returns a status of 'critical'" do
      get "/healthcheck"
      expect(data.fetch(:status)).to eq("critical")
    end
  end

  it "includes useful information about each check" do
    get "/healthcheck"

    expect(data.fetch(:checks)).to include(
      database_connectivity: { status: "ok" },
      queue_latency:         { status: "ok", queues: a_kind_of(Hash) },
      queue_size:            { status: "ok", queues: a_kind_of(Hash) },
      redis_connectivity:    { status: "ok" },
      retry_size:            { status: "ok", retry_size: 0 },
      subscription_content:  { status: "ok", critical: 0, warning: 0 },
      technical_failure:     hash_including(status: "ok", failing: 0),
    )
  end
end
