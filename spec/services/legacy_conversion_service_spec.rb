RSpec.describe LegacyConversionService do
  describe ".call" do
    it 'converts a legacy subscriber list containing a tag' do
      list = build(:subscriber_list, tags: { topics: ["environmental-management/boating"] })
      list.save!(validate: false)

      list.reload
      expect(list['tags']).to eq('topics' => ["environmental-management/boating"])

      LegacyConversionService.call

      list.reload
      expect(list['tags']).to eq('topics' => { 'any' => ["environmental-management/boating"] })
    end
    it 'converts a legacy subscriber list containing links' do
      list = build(:subscriber_list, links: { topics: %w[abc], organisation: %w[123] })
      list.save!(validate: false)

      list.reload
      expect(list['links']).to eq('topics' => %w[abc], 'organisation' => %w[123])

      LegacyConversionService.call

      list.reload
      expect(list['links']).to eq('topics' => { "any" => %w[abc] }, 'organisation' => { "any" => %w[123] })
    end
    it 'does not touch new subscriber lists' do
      list = create(:subscriber_list, links: { topics: { any: %w[abc] }, organisation: { any: %w[123] } })
      list.reload
      expect(list['links']).to eq('topics' => { "any" => %w[abc] }, 'organisation' => { "any" => %w[123] })

      LegacyConversionService.call

      list.reload
      expect(list['links']).to eq('topics' => { "any" => %w[abc] }, 'organisation' => { "any" => %w[123] })
    end
  end
end
