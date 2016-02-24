FactoryGirl.define do
  factory :subscriber_list do
    sequence(:gov_delivery_id) {|n| "UKGOVUK_#{n}" }
    tags({ topics: ["motoring/road_rage"] })
  end
end
