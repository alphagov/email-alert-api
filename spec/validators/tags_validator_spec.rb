RSpec.describe TagsValidator do
  class TagsValidatable
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_accessor :tags
    validates :tags, tags: true
  end

  subject(:model) { TagsValidatable.new }

  context "when valid tags are provided" do
    before {
      model.tags = {
        topics: { any: %w[dogs cats], all: %w[horses] },
        policies: { any: %w[wWelcome1098-_/], all: %w[news_story] },
        commodity_type: { any: %w[f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a], all: %w[123-Abc] },
      }
    }

    it { is_expected.to be_valid }
  end

  context "when invalid tags are provided" do
    before {
      model.tags = {
        organisations: { any: %w[dogs cats] },
        topics: { any: %w[dogs cats] },
        foo: { any: %w([dogs] !cats) },
        people: { any: %w[\u0000] },
        world_locations: { any: "dogs" },
        policies: { any: "><script>alert(1);</script>" },
      }
    }

    it "has an error" do
      expect(model.valid?).to be false
      expect(model.errors[:tags]).to match([
        "All tag values must be sent as Arrays",
        "organisations, foo, people, and world_locations are not valid tags.",
        "foo, people, and policies has a value with an invalid format.",
      ])
    end
  end
end
