class SpamReportService < ApplicationService
  attr_reader :subscriber

  def initialize(subscriber)
    @subscriber = subscriber
  end

  def call
    UnsubscribeAllService.call(subscriber, :marked_as_spam)
  end
end
