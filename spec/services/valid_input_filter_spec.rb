require "spec_helper"

require "valid_input_filter"

RSpec.describe ValidInputFilter do
  subject(:filter) do
    ValidInputFilter.new(
      validators: validators,
      service: service,
      context: context,
    )
  end

  let(:service) { double(:service) }
  let(:context) { double(:context) }

  let(:true_validator) { double(:true_validator, valid?: true) }
  let(:false_validator) { double(:false_validator, valid?: false) }

  context "with only validators that return true" do
    let(:validators) {
      [
        true_validator,
        true_validator,
      ]
    }

    it "calls the service with the context" do
      expect(service).to receive(:call).with(context)

      filter.call
    end
  end

  context "with any validators that return false" do
    let(:validators) {
      [
        true_validator,
        false_validator,
        true_validator,
      ]
    }

    it "calls #unprocessable on the context with an error message" do
      expect(context).to receive(:unprocessable).with(
        hash_including(error: /invalid/)
      )

      filter.call
    end
  end
end
