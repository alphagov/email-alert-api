RSpec.describe EmailTemplateContext do
  describe "#add_utm" do
    it "handles empty query parameters" do
      expect(
        EmailTemplateContext.new.add_utm("https://redirect.to/somewhere", {}),
      ).to eq("https://redirect.to/somewhere?")
    end

    it "adds query parameters" do
      expect(
        EmailTemplateContext.new.add_utm("https://redirect.to/somewhere", a: 3, b: 4),
      ).to eq("https://redirect.to/somewhere?a=3&b=4")
    end

    it "adds query parameters when there are existing query parameters" do
      expect(
        EmailTemplateContext.new.add_utm("https://redirect.to/somewhere?c=1", a: 3, b: 4),
      ).to eq("https://redirect.to/somewhere?c=1&a=3&b=4")
    end
  end
end
