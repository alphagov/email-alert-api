RSpec.describe "Healthcheck", type: :request do
  context "when the healthchecks pass" do
    it "returns a status of 'ok'" do
      get "/healthcheck"
      expect(data.fetch(:status)).to eq("ok")
    end
  end

  it "includes useful information about each check" do
    get "/healthcheck"

    expect(data.fetch(:checks)).to include(
      database_connectivity: { status: "ok" },
      redis_connectivity:    { status: "ok" },
      sidekiq_queue_latency: hash_including(status: "ok", queues: a_kind_of(Hash)),
      sidekiq_retry_size:    hash_including(status: "ok", value: 0),
    )
  end
end
