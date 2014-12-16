require "rails_helper"

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
      allow_any_instance_of(HealthcheckController).to receive(:queue_size).and_return(13)
      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']).to include('queue_size')
    end

    it "returns ok for small queue sizes" do
      allow_any_instance_of(HealthcheckController).to receive(:queue_size).and_return(1)

      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']['queue_size']['status']).to eq('ok')
    end

    it "returns warning for medium queue sizes" do
      allow_any_instance_of(HealthcheckController).to receive(:queue_size).and_return(4)

      get :check, format: :json

      data = JSON.parse(response.body)
      expect(data['checks']['queue_size']['status']).to eq('warning')
    end

    it "returns critical for large queue sizes" do
      allow_any_instance_of(HealthcheckController).to receive(:queue_size).and_return(10)

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
  end
end
