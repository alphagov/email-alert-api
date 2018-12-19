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


  describe '.uncall' do
    it 'reverts a subscriber list containing a tag' do
      list = create(:subscriber_list, tags: { topics: { any: ["environmental-management/boating"] } })
      LegacyConversionService.uncall
      list.reload
      expect(list['tags']).to eq('topics' => ["environmental-management/boating"])
    end

    it 'reverts a subscriber list containing a link' do
      list = create(:subscriber_list, links: { topics: { any: %w[abc] }, organisation: { any: %w[123] } })
      LegacyConversionService.uncall
      list.reload
      expect(list['links']).to eq('topics' => %w[abc], 'organisation' => %w[123])
    end

    it 'reverts a subscriber list containing a link' do
      list = create(:subscriber_list, links: { topics: { any: %w[abc] }, organisation: { any: %w[123] } })
      LegacyConversionService.uncall
      list.reload
      expect(list['links']).to eq('topics' => %w[abc], 'organisation' => %w[123])
    end

    it 'ignores "all" when reverting' do
      list = create(:subscriber_list, links: { topics: { all: %w[abc] }, organisation: { all: %w[123] } })
      LegacyConversionService.uncall
      list.reload
      expect(list['links']).to eq('topics' => [], 'organisation' => [])
    end

    it 'does not convert legacy lists' do
      list = build(:subscriber_list, links: { topics: %w[abc], organisation: %w[123] },
                                     tags: { topics: ["environmental-management/boating"] })
      list.save!(validate: false)

      LegacyConversionService.uncall
      list.reload
      expect(list['links']).to eq('topics' => %w[abc], 'organisation' => %w[123])
      expect(list['tags']).to eq('topics' => ["environmental-management/boating"])
    end
  end
end
