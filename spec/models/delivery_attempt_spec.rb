require "rails_helper"

RSpec.describe DeliveryAttempt, type: :model do
  shared_examples "is marked as a failure" do
    it "is marked as a failure" do
      expect(subject.failure?).to be_truthy
    end
  end

  shared_examples "is marked as should retry" do
    it "is marked as should retry" do
      expect(subject.should_retry?).to be_truthy
    end
  end

  shared_examples "is not marked as should retry" do
    it "is not marked as should retry" do
      expect(subject.should_retry?).to be_falsey
    end
  end

  describe "validations" do
    subject { create(:delivery_attempt) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end
  end

  context "with a permanent failure" do
    subject { create(:delivery_attempt, status: :permanent_failure) }

    include_examples "is marked as a failure"
    include_examples "is not marked as should retry"

    it "is marked as remove the subscriber" do
      expect(subject.should_remove_subscriber?).to be_truthy
    end
  end

  context "with a temporary failure" do
    subject { create(:delivery_attempt, status: :temporary_failure) }

    include_examples "is marked as a failure"
    include_examples "is marked as should retry"
  end

  context "with a technical failure" do
    subject { create(:delivery_attempt, status: :technical_failure) }

    include_examples "is marked as a failure"
    include_examples "is marked as should retry"
  end

  context "with an internal failure" do
    subject { create(:delivery_attempt, status: :internal_failure) }

    include_examples "is marked as a failure"
    include_examples "is not marked as should retry"

    it "is marked as should report failure" do
      expect(subject.should_report_failure?).to be_truthy
    end
  end
end
