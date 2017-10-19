FactoryGirl.define do
  factory :subscriber_list do
    sequence(:gov_delivery_id) {|n| "UKGOVUK_#{n}" }
    tags({ topics: ["motoring/road_rage"] })
    created_at { 1.year.ago }
  end

  factory :notification_log do
    sequence(:govuk_request_id) { |i| "request-id-#{i}" }
    sequence(:content_id) { |i| "content-id-#{i}" }
    public_updated_at Time.now.to_s
    links {}
    tags {}
    document_type "announcement"
    gov_delivery_ids %w(TOPIC_123 TOPIC_456)
  end

  factory :subscriber do
  end
end
