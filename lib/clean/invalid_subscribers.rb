require "csv"

module Clean
  class InvalidSubscribers
    MIN_FAILURES = 5

    def initialize(sent_csv:, failed_csv:)
      @sent_rows = CSV.new(sent_csv, headers: true).to_a
      @failed_rows = CSV.new(failed_csv, headers: true).to_a
      if @failed_rows.count > @sent_rows.count
        raise "Are the sent and failed csv files swapped?"
      end
    end

    def deactivate_subscribers(dry_run: true)
      rows_to_remove = remove_rows_with_successes remove_rows_without_failures @failed_rows
      subscriber_ids_to_remove = rows_to_remove.map { |row| row.fetch("subscriber_id") }
      subscribers_to_remove =  Subscriber.where(id: subscriber_ids_to_remove).activated
      puts "Removing the following email subscriptions"
      puts subscribers_to_remove.pluck(:address)
      subscribers_to_remove.update_all(deactivated_at: Time.zone.now) unless dry_run
    end

  private

    def remove_rows_without_failures(failed_rows)
      failed_rows.reject { |row| row.fetch("count").to_i < MIN_FAILURES }
    end

    def remove_rows_with_successes(failed_rows)
      sent_hash = rows_to_hash(@sent_rows)
      failed_rows.reject do |row|
        subscriber_id = row.fetch("subscriber_id")
        sent_hash.fetch(subscriber_id, 0).to_i.positive?
      end
    end

    def rows_to_hash(rows)
      rows.each_with_object({}) do |row, result|
        result[row.fetch("subscriber_id")] = row.fetch("count")
      end
    end
  end
end
