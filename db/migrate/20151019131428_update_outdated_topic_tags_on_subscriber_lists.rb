# rubocop:disable Lint/UnreachableCode

class UpdateOutdatedTopicTagsOnSubscriberLists < ActiveRecord::Migration[4.2]
  def up
    return

    tag_mappings = [
      {
        from: 'schools-colleges/behaviour-attendance',
        to: 'schools-colleges-childrens-services/school-behaviour-attendance'
      },
      {
        from: 'schools-colleges/administration-finance',
        to: 'schools-colleges-childrens-services/school-college-funding-finance'
      },
      {
        from: 'schools-colleges/curriculum-qualifications',
        to: 'schools-colleges-childrens-services/curriculum-qualifications'
      },
      {
        from: 'schools-colleges/governance',
        to: 'schools-colleges-childrens-services/running-school-college'
      },
      {
        from: 'farming-food-grants-payments/export-refunds',
        to: 'business-tax/import-export'
      },
      {
        from: 'farming-food-grants-payments/environmental-land-management',
        to: 'environmental-management/land-management'
      },
      {
        from: 'farming-food-grants-payments/promotion-schemes',
        to: 'government/government-funding-programmes'
      },
    ]

    tag_mappings.each do |mapping|
      list = FindExactMatch.new.call(topics: [mapping[:from]]).first
      if list.present?
        list.tags = { topics: [mapping[:to]] }
        list.save!
      end
    end
  end
end
