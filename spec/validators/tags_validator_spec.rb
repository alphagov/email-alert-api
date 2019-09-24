RSpec.describe TagsValidator do
  class TagsValidatable
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_accessor :tags
    validates :tags, tags: true
  end

  subject(:model) { TagsValidatable.new }

  context "when valid tags are provided" do
    before { model.tags = { topics: { any: %w(dogs cats), all: %w(horses) } } }
    it { is_expected.to be_valid }
  end

  context "when invalid tags are provided" do
    before {
      model.tags = {
        organisations: { any: %w(dogs cats) },
        topics: { any: %w(dogs cats) },
        foo: { any: %w(dogs cats) },
        people: { any: %w(dogs cats) },
        world_locations: { any: "dogs" },
      }
    }

    it "has an error" do
      expect(model.valid?).to be false
      expect(model.errors[:tags]).to match([
        "All tag values must be sent as Arrays",
        "organisations, foo, people, and world_locations are not valid tags.",
      ])
    end
  end
end
