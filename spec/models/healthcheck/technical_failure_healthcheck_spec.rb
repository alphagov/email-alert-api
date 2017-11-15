require "rails_helper"

RSpec.describe Healthcheck::TechnicalFailureHealthcheck do
  def create_delivery_attempt(status, updated)
    FactoryGirl.create(:delivery_attempt, status: status, updated_at: updated)
  end

  context "when there are no technical failures" do
    before { create_delivery_attempt(:delivered, 1.minute.ago) }
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when there are technical failures" do
    context "within the last hour" do
      before { create_delivery_attempt(:technical_failure, 59.minutes.ago) }
      specify { expect(subject.status).to eq(:critical) }
    end

    context "within the last day" do
      before { create_delivery_attempt(:technical_failure, 23.hours.ago) }
      specify { expect(subject.status).to eq(:warning) }
    end

    context "older than a day" do
      before { create_delivery_attempt(:technical_failure, 25.hours.ago) }
      specify { expect(subject.status).to eq(:ok) }
    end
  end

  describe "#details" do
    before do
      3.times { create_delivery_attempt(:technical_failure, 30.minutes.ago) }
      5.times { create_delivery_attempt(:technical_failure, 90.minutes.ago) }
    end

    it "counts how many failures there have been over the course of a day" do
      details = subject.details

      expect(details.fetch(:last_1_hours)).to eq(3)
      expect(details.fetch(:last_2_hours)).to eq(8)
      expect(details.fetch(:last_3_hours)).to eq(8)
    end
  end
end
