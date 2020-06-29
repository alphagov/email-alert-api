RSpec.describe "manage" do
  describe "hash_to_table" do
    it "converts a hash to table markdown" do
      hash = [{ foo: "bar", baz: 12_345 }, { foo: "Long bar", baz: 12 }]
      expected_markdown = <<~MARKDOWN
        | Foo      | Baz   |
        | bar      | 12345 |
        | Long bar | 12    |
      MARKDOWN
      expect(hash_to_table(hash)).to eq(expected_markdown)
    end

    it "converts non-string values to string" do
      hash = [{ timestamp: Time.zone.parse("2020-06-29 15:18:48") }]
      expected_markdown = <<~MARKDOWN
        | Timestamp                 |
        | 2020-06-29 15:18:48 +0100 |
      MARKDOWN
      expect(hash_to_table(hash)).to eq(expected_markdown)
    end
  end
end
