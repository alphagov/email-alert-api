class Overloader
  def initialize(requested_volume)
    @requested_volume = requested_volume
  end

  def with_big_lists
    generate_emails(SubscriberList.all.sort_by { |list| -list_size(list) })
  end

  def with_small_lists
    generate_emails(SubscriberList.all.sort_by { |list| list_size(list) })
  end

private

  attr_reader :requested_volume

  def generate_emails(sorted_lists)
    generated_volume = 0

    while generated_volume < requested_volume
      content_change = create_fake_content_change

      generated_volume += generate_matches(
        content_change,
        sorted_lists,
        requested_volume - generated_volume,
      )

      ProcessContentChangeAndGenerateEmailsWorker
        .perform_async(content_change.id)
    end
  end

  def generate_matches(content_change, sorted_lists, volume)
    generated_volume = 0
    total_lists = 0

    sorted_lists.each do |list|
      next if list_size(list).zero?
      break if generated_volume >= volume

      generated_volume += list_size(list)
      total_lists += 1

      MatchedContentChange.create!(
        content_change: content_change, subscriber_list: list,
      )
    end

    raise "Aborting as no lists have subscribers" if generated_volume.zero?

    puts "Generated fake matches against #{total_lists} lists"
    puts "Preparing to send #{generated_volume} emails via these lists"
    generated_volume
  end

  def list_size(list)
    list.subscriptions.active.immediately.count
  end

  def create_fake_content_change
    content_change = ContentChange.create(
      publishing_app: "test",
      document_type: "test",
      govuk_request_id: 1,
      government_document_supertype: "test",
      email_document_supertype: "test",
      content_id: SecureRandom.uuid,
      public_updated_at: Time.zone.now,
      change_note: "test",
      base_path: "/test",
      title: "Test",
      description: "test",
    )

    puts "Created fake content change #{content_change.content_id}"
    content_change
  end
end
