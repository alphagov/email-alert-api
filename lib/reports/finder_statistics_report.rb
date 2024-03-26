require "reports/concerns/notification_stats"

class Reports::FinderStatisticsReport
  include Reports::Concerns::NotificationStats

  attr_reader :govuk_path

  def initialize(govuk_path)
    @govuk_path = govuk_path
  end

  def call
    lists = SubscriberListsForFinderQuery.new(govuk_path:).call

    output_string = "\nLists created from this finder\n"

    list_names_array(lists).each { |ln| output_string += " - #{ln}\n" }

    output_string += "\nResulting in:\n"

    list_stats_array(lists).each { |ls| output_string += " - #{ls}\n" }

    output_string
  rescue SubscriberListsForFinderQuery::NotAFinderError
    ["This item is not a finder, so isn't suitable for this report."]
  end
end
