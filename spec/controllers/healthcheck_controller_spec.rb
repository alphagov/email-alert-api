require "rails_helper"

ENV['SIDEKIQ_QUEUE_SIZE_WARNING'] = '2'
ENV['SIDEKIQ_QUEUE_SIZE_CRITICAL'] = '5'

ENV['SIDEKIQ_QUEUE_LATENCY_WARNING'] = '5'
ENV['SIDEKIQ_QUEUE_LATENCY_CRITICAL'] = '10'

ENV['SIDEKIQ_RETRY_SIZE_WARNING'] = '5'
ENV['SIDEKIQ_RETRY_SIZE_CRITICAL'] = '10'

RSpec.describe HealthcheckController, type: :controller do
  describe "#check" do
    it "responds with JSON" do
      get :check, format: :json

      expect(response.status).to eq(200)
      expect(response.content_type).to eq('application/json')

      data = JSON.parse(response.body)
    end

    it "responds with 'ok'" do
      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['status']).to eq('ok')
    end

    it "includes queue length check in the response" do
      queues = {
        "scheduled_publishing"=>0,
        "panopticon"=>1
      }

      allow_any_instance_of(HealthcheckController).to receive(:sidekiq_queues).and_return(queues)
      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']).to include('queue_size')
    end

    it "returns ok for small queue sizes" do
      queues = {
        "scheduled_publishing"=>0,
        "panopticon"=>1
      }

      allow_any_instance_of(HealthcheckController).to receive(:sidekiq_queues).and_return(queues)

      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']['queue_size']['status']).to eq('ok')
    end

    it "returns warning for medium queue sizes" do
      queues = {
        "scheduled_publishing"=>0,
        "panopticon"=>1,
        "foo"=>3
      }

      allow_any_instance_of(HealthcheckController).to receive(:sidekiq_queues).and_return(queues)

      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']['queue_size']['status']).to eq('warning')
    end

    it "returns critical for large queue sizes" do
      queues = {
        "scheduled_publishing"=>0,
        "panopticon"=>1,
        "foo"=>10
      }

      allow_any_instance_of(HealthcheckController).to receive(:sidekiq_queues).and_return(queues)

      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']['queue_size']['status']).to eq('critical')
    end

    it "includes queue age check in the response" do
      allow_any_instance_of(HealthcheckController).to receive(:queue_age).and_return(3600.5)
      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']).to include('queue_age')
    end

    it "returns critical for large latencies" do
      latencies = {
        "foo"=>1,
        "bar"=>5,
        "baz"=>10
      }

      allow_any_instance_of(HealthcheckController).to receive(:queue_latencies).and_return(latencies)

      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']['queue_age']['status']).to eq('critical')

    end

  end
end
