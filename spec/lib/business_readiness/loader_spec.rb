RSpec.describe BusinessReadiness::Loader do
  subject do
    path = File.join(File.dirname(__FILE__), "/examples/#{fixture}.csv")
    facets_path = File.join(File.dirname(__FILE__), "/examples/facet_config.yml")
    described_class.new(path, facets_path).base_paths_with_tags
  end

  context "with specific tags" do
    let(:fixture) { "specific" }

    it "should load the specific tags" do
      specific = subject.fetch("/specific")

      expect(specific["sector_business_area"]).to match_array(%w(aerospace agriculture))
    end
  end

  context "with multiple base paths" do
    let(:fixture) { "multiple" }

    it "should load all the base paths" do
      expect(subject.length).to eq(5)
    end
  end
end
