RSpec.describe ImmediateEmailGenerationWorker do
  describe ".perform" do
    it "can be called" do
      described_class.new.perform
    end
  end
end
