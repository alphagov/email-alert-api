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

  context "with nil existing tags" do
    let(:existing_tags) { nil }

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
    context "as an array" do
      let(:existing_tags) do
        { "sector_business_area" => %w(chemicals) }
      end

      it "should have both the old and new values" do
        expect(subject["sector_business_area"]).to match_array(
          %w(aerospace automotive chemicals)
        )
      end
    end

    context "as a string" do
      let(:existing_tags) do
        { "sector_business_area" => "chemicals" }
      end

      it "should have both the old and new values" do
        expect(subject["sector_business_area"]).to match_array(
          %w(aerospace automotive chemicals)
        )
      end
    end

    context "as nil" do
      let(:existing_tags) do
        { "sector_business_area" => nil }
      end

      it "should have the new values" do
        expect(subject["sector_business_area"]).to match_array(
          %w(aerospace automotive)
        )
      end
    end

    context "and appear_in_find_eu_exit_guidance_business_finder tag" do
      let(:existing_tags) do
        {
          "appear_in_find_eu_exit_guidance_business_finder" => "no"
        }
      end

      it "should come back as yes" do
        expect(subject["appear_in_find_eu_exit_guidance_business_finder"]).to eq("yes")
      end
    end
  end

  context "without matching base path" do
    let(:base_path) { "/no-example" }

    context "it passes back whatever was given to it" do
      context "when nil" do
        let(:existing_tags) { nil }
        it { is_expected.to eq(nil) }
      end

      context "when an empty hash" do
        let(:existing_tags) { {} }
        it { is_expected.to eq({}) }
      end

      context "when a non-empty hash" do
        let(:existing_tags) { { tag: %w(value) } }
        it { is_expected.to eq(tag: %w(value)) }
      end

      context "when a string" do
        let(:existing_tags) { "tag" }
        it { is_expected.to eq("tag") }
      end
    end
  end
end
