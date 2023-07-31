require "reports/concerns/notification_stats"

class Reports::HistoricalContentChangeStatisticsReport
  include Reports::Concerns::NotificationStats

  attr_reader :govuk_path

  def initialize(govuk_path)
    @govuk_path = govuk_path
  end

  def call
    content_changes = ContentChange.where(base_path: govuk_path).order(:public_updated_at)

    if content_changes.any?
      output_string = "#{content_changes.count} content changes registered for #{govuk_path}.\n\n"

      content_changes.each do |cc|
        output_string += "Content change on #{cc.public_updated_at}:\n"

        lists = SubscriberListQuery.new(content_id: cc.content_id, tags: cc.tags, links: cc.links, document_type: cc.document_type, email_document_supertype: cc.email_document_supertype, government_document_supertype: cc.government_document_supertype).lists

        list_stats_array(lists).each { |ls| output_string += " - #{ls}\n" }
      end

      output_string
    else
      "No content changes registered for path: #{govuk_path}"
    end
  end
end
