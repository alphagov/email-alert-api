require "rails_helper"

RSpec.describe HealthcheckController, type: :controller do
  describe "#check" do
    it "responds with JSON" do
      get :check

      expect(response.status).to eq(200)
      expect(response.content_type).to eq('application/json')

      data = JSON.parse(response.body)
    end

    it "responds with 'ok'" do
      get :check

      data = JSON.parse(response.body)
      expect(data['status']).to eq('ok')
    end

    it "includes queue length in the response" do
      allow_any_instance_of(HealthcheckController).to receive(:queue_size).and_return(13)
      get :check

      data = JSON.parse(response.body)
      expect(data['checks']['queue_size']).to eq(13)
    end

    it "includes queue age in the response" do
      allow_any_instance_of(HealthcheckController).to receive(:queue_age).and_return(3600.5)
      get :check

      data = JSON.parse(response.body)
      expect(data['checks']['queue_age']).to eq(3600.5)
    end
  end
end
