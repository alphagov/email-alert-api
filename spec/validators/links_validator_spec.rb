RSpec.describe LinksValidator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      include ActiveModel::Model

      attr_accessor :links

      validates :links, links: true
    end
  end

  it "is valid when links match a UUID formatting" do
    record = record_class.new(links: {
      commodity_type: { any: %w[f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a] },
    })

    expect(record).to be_valid
  end

  it "is invalid when links with other formats are provided" do
    record = record_class.new(links: {
      organisations: { any: %w[dogs cats] },
      countries: { any: %w[dogs cats] },
      foo: { any: %w([dogs] !cats) },
      people: { any: %w[\u0000] },
      taxon_tree: { any: "><script>alert(1);</script>" },
    })

    expect(record).to be_invalid
    expect(record.errors[:links]).to match([
      "foo, people, and taxon_tree has a value with an invalid format.",
    ])
  end
end
