require "reports/concerns/notification_stats"
require "content_item_list_query"

class Reports::FutureContentChangeStatisticsReport
  include Reports::Concerns::NotificationStats

  attr_reader :govuk_path, :draft

  def initialize(govuk_path, draft)
    @govuk_path = govuk_path
    @draft = draft
  end

  def call
    unless EmailCriteriaQuery.new(govuk_path:, draft:).call
      return [
        "This item would not trigger an email alert itself.",
        "However, it might have a subscriber list that would be triggered by",
        "changes to other pages. Try running the",
        "report:subscriber_list_subscriber_count rake task",
      ]
    end

    lists = SubscriberListsByPathQuery.new(govuk_path:, draft:).call

    output_string = change_messages.join

    list_names_array(lists).each { |ln| output_string += " - #{ln}\n" }

    output_string += "\nResulting in:\n"

    list_stats_array(lists).each { |ls| output_string += " - #{ls}\n" }

    output_string
  end

  def change_messages
    if @draft
      [
        "Publishing the drafted changes to #{@govuk_path} will trigger alerts on these lists:\n",
        "(NB: publishing as a minor change will not trigger alerts)",
      ]
    else
      [
        "Publishing major changes to the information on #{@govuk_path} will trigger alerts on these lists:\n",
        "(NB: If major changes involve changes to the taxons/links/etc these lists will change)\n",
      ]
    end
  end
end
