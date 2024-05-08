RSpec.describe TagsValidator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      include ActiveModel::Model

      attr_accessor :tags

      validates :tags, tags: true
    end
  end

  let(:valid_tags) { %w[alpha-numeric-123 Capitals underscores_ slash/separated] }

  it "is valid when tags meet the formatting rules" do
    record = record_class.new(tags: { tribunal_decision_categories: { any: valid_tags } })
    expect(record).to be_valid
  end

  it "is invalid when tag values aren't set as an array" do
    record = record_class.new(tags: { tribunal_decision_categories: { any: "a-tag" } })
    expect(record).to be_invalid
    expect(record.errors[:tags]).to match(["All tag values must be sent as Arrays"])
  end

  it "is invalid when a tag key is given that isn't defined as a ValidTag" do
    record = record_class.new(tags: { animals: { any: valid_tags } })
    expect(ValidTags::ALLOWED_TAGS).not_to include("animals")
    expect(record).to be_invalid
    expect(record.errors[:tags]).to match(["animals are not valid tags."])
  end

  it "is invalid when the value for a tag doesn't match the allowed characters" do
    record = record_class.new(tags: { tribunal_decision_categories: { any: ["<script>"] } })
    expect(record).to be_invalid
    expect(record.errors[:tags]).to match(["tribunal_decision_categories has a value with an invalid format."])
  end
end
