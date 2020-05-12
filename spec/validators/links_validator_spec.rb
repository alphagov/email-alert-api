RSpec.describe LinksValidator do
  class LinksValidatable
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_accessor :links
    validates :links, links: true
  end

  subject(:model) { LinksValidatable.new }

  context "when valid links are provided" do
    before do
      model.links = {
        commodity_type: { any: %w[f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a] },
      }
    end

    it { is_expected.to be_valid }
  end

  context "when invalid links are provided" do
    before do
      model.links = {
        organisations: { any: %w[dogs cats] },
        topics: { any: %w[dogs cats] },
        foo: { any: %w([dogs] !cats) },
        people: { any: %w[\u0000] },
        policies: { any: "><script>alert(1);</script>" },
      }
    end

    it "has an error" do
      expect(model.valid?).to be false
      expect(model.errors[:links]).to match([
        "foo, people, and policies has a value with an invalid format.",
      ])
    end
  end
end
