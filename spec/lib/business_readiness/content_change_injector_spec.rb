RSpec.describe BusinessReadiness::ContentChangeInjector do
  let(:base_path) { "/example" }
  let(:base_paths_with_tags) do
    {
      "/example" => {
        "appear_in_find_eu_exit_guidance_business_finder" => "yes",
        "sector_business_area" => %w(aerospace automotive),
        "intellectual_property" => %w(copyright patents)
      }
    }
  end

  subject { described_class.new(base_paths_with_tags).inject(base_path, existing_tags) }

  context "with no existing tags" do
    let(:existing_tags) { {} }

    it "should have all the new tags" do
      expect(subject).to eq(base_paths_with_tags["/example"])
    end
  end

  context "with some unrelated existing tags" do
    let(:existing_tags) do
      {
        "unrelated_tag" => %w(test)
      }
    end

    it "should have all the new tags and the existing tags" do
      expect(subject).to eq(
        base_paths_with_tags["/example"].merge("unrelated_tag" => %w(test))
      )
    end
  end

  context "with some related existing tags" do
    let(:existing_tags) do
      {
        "sector_business_area" => %w(chemicals)
      }
    end

    it "should have both the old and new values" do
      expect(subject["sector_business_area"]).to match_array(
        %w(aerospace automotive chemicals)
      )
    end
  end
end
