require 'rails_helper'
require 'gds_api/test_helpers/content_store'

RSpec.describe ContentItem do
  include ::GdsApi::TestHelpers::ContentStore

  describe 'title' do
    it 'gets the title from the content store' do
      content_store_has_item(
        '/redirected/path',
        {
          'base_path' => '/redirected/path',
          'title' => 'redirected title'
        }.to_json
      )
      expect(ContentItem.new('/redirected/path').title).to eq('redirected title')
    end
    it 'returns a default value as the title if the base path does not exist' do
      content_store_does_not_have_item('/redirected/path')
      expect(ContentItem.new('/redirected/path').title).to eq(ContentItem::DEFAULT)
    end
    it 'returns  a default value as the title if the title does not exist' do
      content_store_has_item(
        '/redirected/path',
        {
          'base_path' => '/redirected/path',
          'title' => nil
        }.to_json
      )
      expect(ContentItem.new('/redirected/path').title).to eq(ContentItem::DEFAULT)
    end
  end
  describe 'url' do
    it 'returns the full URL' do
      expect(ContentItem.new('/redirected/path').url).to eq("http://www.dev.gov.uk/redirected/path")
    end
  end
end
