class Reports::ContentChangeStatisticsReport
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def call
    content_changes = ContentChange.where(base_path: url).order(:public_updated_at)

    if content_changes.any?
      output_string = "#{content_changes.count} content changes registered for #{url}.\n\n"

      content_changes.each do |cc|
        output_string += "Content change on #{cc.public_updated_at}:\n"

        lists = SubscriberListQuery.new(content_id: cc.content_id, tags: cc.tags, links: cc.links, document_type: cc.document_type, email_document_supertype: cc.email_document_supertype, government_document_supertype: cc.government_document_supertype).lists

        total_subs = lists.sum { |l| l.subscriptions.active.count }
        immediately_subs = lists.sum { |l| l.subscriptions.active.immediately.count }
        daily_subs = lists.sum { |l| l.subscriptions.active.daily.count }
        weekly_subs = lists.sum { |l| l.subscriptions.active.weekly.count }

        output_string += " - notified immediately: #{immediately_subs}\n"
        output_string += " - notified next day:    #{daily_subs}\n"
        output_string += " - notified at weekend:  #{weekly_subs}\n"
        output_string += " - notified total:       #{total_subs}\n\n"
      end

      output_string
    else
      "No content changes registered for that URL: #{url}"
    end
  end
end
