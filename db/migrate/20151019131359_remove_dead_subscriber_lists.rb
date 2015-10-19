class RemoveDeadSubscriberLists < ActiveRecord::Migration
  def up
    [
      # redirected to 'prisons-probation'
      'prisons-probation/researching-prisons',
      # redirected to 'climate-change-energy'
      'environmental-management/climate-change-energy',
      # redirected to 'government/collections/eea-swiss-nationals-and-ec-association-agreements-modernised-guidance',
      'immigration-operational-guidance/european-casework-instructions',
      # not present in content store
      'pharmaceutical-industry/advertising-medicines',
    ].each do |topic_path|
      list = SubscriberListQuery.new.find_exact_match_with(topics: [topic_path]).first
      if list.present?
        list.destroy!
      end
    end
  end

  def down
    #noop
  end
end
