require "spec_helper"

require "tag_set_domain_aspect"

RSpec.describe TagSetDomainAspect do
  subject(:aspect) {
    TagSetDomainAspect.new(
      factory: factory,
      service: service,
      context: context,
      tags: tags,
    )
  }

  let(:service) { double(:service, call: nil) }
  let(:factory) { double(:factory, call: nil) }
  let(:context) { double(:context) }
  let(:tags) { double(:tags) }
  let(:tag_set_domain_object) { double(:tag_set_domain_object) }

  describe "#call" do
    it "creates a domain object from the params" do
      aspect.call

      expect(factory).to have_received(:call).with(tags)
    end

    it "calls the service with context and the new TagSet object" do
      allow(factory).to receive(:call).and_return(tag_set_domain_object)

      aspect.call

      expect(service).to have_received(:call)
        .with(context, tags: tag_set_domain_object)
    end
  end
end
