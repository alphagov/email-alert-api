RSpec.describe BusinessReadiness::Loader do
  subject do
    path = File.join(File.dirname(__FILE__), "/examples/#{fixture}.csv")
    described_class.new(path).base_paths_with_tags
  end

  context "with specific tags" do
    let(:fixture) { "specific" }

    it "should only load the appear_in_find_eu_exit_guidance_business_finder tag" do
      specific = subject.fetch("/specific")

      expect(specific["appear_in_find_eu_exit_guidance_business_finder"]).to eq("yes")
    end
  end

  context "with multiple base paths" do
    let(:fixture) { "multiple" }

    it "should load all the base paths" do
      expect(subject.length).to eq(5)
    end
  end
end
