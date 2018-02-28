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
  end

  factory :digest_run do
    date { Date.current }
    range Frequency::DAILY

    trait :daily

    trait :weekly do
      range Frequency::WEEKLY
    end
  end

  factory :digest_run_subscriber do
    digest_run
    subscriber
  end

  factory :email, aliases: [:unarchivable_email] do
    address "test@example.com"
    subject "subject"
    body "body"

    factory :archivable_email do
      finished_sending_at { 2.days.ago }
    end

    factory :archived_email do
      finished_sending_at { 2.days.ago }
      archived_at { 1.day.ago }
    end
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

    trait :activated

    trait :deactivated do
      deactivated_at { Time.now }
    end

    trait :nullified do
      address nil
      deactivated_at { Time.now }
    end
  end

  factory :subscriber_list do
    sequence(:title) { |n| "title #{n}" }
    sequence(:gov_delivery_id) { |n| "UKGOVUK_#{n}" }
    tags(topics: ["motoring/road_rage"])
    created_at { 1.year.ago }

    trait :travel_advice do
      links countries: [SecureRandom.uuid]
    end

    trait :medical_safety_alert do
      tags format: ["medical_safety_alert"], alert_type: %w(devices drugs field-safety-notices company-led-drugs)
    end
  end

  factory :subscription do
    subscriber
    subscriber_list
    frequency Frequency::IMMEDIATELY

    trait :immediately

    trait :daily do
      frequency Frequency::DAILY
    end

    trait :weekly do
      frequency Frequency::WEEKLY
    end

    trait :ended do
      ended_at { Time.now }
      ended_reason :unsubscribed
    end
  end

  factory :subscription_content do
    subscription
    content_change

    trait :with_archivable_email do
      association :email, factory: :archivable_email
    end
  end

  factory :matched_content_change do
    content_change
    subscriber_list
  end

  factory :user
end
