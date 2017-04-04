FactoryGirl.define do
  factory :subscriber_list do
    sequence(:gov_delivery_id) {|n| "UKGOVUK_#{n}" }
    tags({ topics: ["motoring/road_rage"] })
    created_at { 1.year.ago }
  end
end
