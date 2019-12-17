RSpec.describe "Healthcheck", type: :request do
  context "when the healthchecks pass" do
    it "returns a status of 'ok'" do
      get "/healthcheck"
      expect(data.fetch(:status)).to eq("ok")
    end
  end

  context "when one of the healthchecks is warning" do
    before do
      allow_any_instance_of(Healthcheck::QueueSize)
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
      allow(ActiveRecord::Base).to receive(:connection).and_return(true)
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
      content_changes:       { status: "ok", critical: 0, warning: 0 },
      digest_runs:           { status: "ok", critical: 0, warning: 0 },
      redis_connectivity:    { status: "ok" },
      sidekiq_queue_latency: hash_including(status: "ok", queues: a_kind_of(Hash)),
      sidekiq_queue_size:    hash_including(status: "ok", queues: a_kind_of(Hash)),
      sidekiq_retry_size:    hash_including(status: "ok", value: 0),
      subscription_contents: hash_including(status: "ok", critical: 0, warning: 0),
    )
  end
end
