RSpec.describe BusinessReadiness::Loader do
  subject do
    path = File.join(File.dirname(__FILE__), "/examples/#{fixture}.csv")
    described_class.new(path).base_paths_with_tags
  end

  context "with all tags" do
    let(:fixture) { "all" }

    it "should include all tags" do
      all = subject.fetch("/all")

      expect(all["appear_in_find_eu_exit_guidance_business_finder"]).to eq("yes")
      expect(all["sector_business_area"].length).to eq(47)
      expect(all["employ_eu_citizens"].length).to eq(3)
      expect(all["doing_business_in_the_eu"].length).to eq(6)
      expect(all["regulations_and_standards"].length).to eq(1)
      expect(all["personal_data"].length).to eq(3)
      expect(all["intellectual_property"].length).to eq(6)
      expect(all["receiving_eu_funding"].length).to eq(9)
      expect(all["public_sector_procurement"].length).to eq(2)
    end
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
