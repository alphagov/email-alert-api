FactoryBot.define do
  factory :content_change do
    content_id { SecureRandom.uuid }
    title "title"
    base_path "government/base_path"
    change_note "change note"
    description "description"
    links Hash.new
    tags Hash.new
    public_updated_at { Time.now.to_s }
    email_document_supertype "email document supertype"
    government_document_supertype "government document supertype"
    sequence(:govuk_request_id) { |i| "request-id-#{i}" }
    document_type "document type"
    publishing_app "publishing app"
  end

  factory :delivery_attempt do
    email
    status :sending
    provider :notify
    reference "reference"
  end

  factory :digest_run do
    date { Date.current }
    range DigestRun::DAILY

    trait :daily

    trait :weekly do
      range DigestRun::WEEKLY
    end
  end

  factory :email do
    address "test@example.com"
    subject "subject"
    body "body"
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
    sequence(:address) { |i| "test-#{i}@example.com" }
  end

  factory :subscriber_list do
    sequence(:title) { |n| "title #{n}" }
    sequence(:gov_delivery_id) { |n| "UKGOVUK_#{n}" }
    tags(topics: ["motoring/road_rage"])
    created_at { 1.year.ago }
  end

  factory :subscription do
    subscriber
    subscriber_list
  end

  factory :subscription_content do
    subscription
    content_change
  end

  factory :user
end
