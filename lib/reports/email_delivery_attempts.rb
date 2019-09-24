require "csv"

module Reports
  class EmailDeliveryAttempts
    def initialize(start_date, end_date)
      @start_date = parse_date(start_date)
      @end_date = parse_date(end_date)
    end

    def report
      date_range = @start_date...@end_date

      puts "Searching for all sucessful delivery attempts between #{start_date} and #{end_date}"

      delivery_attempts = get_email_delivery_attempts(date_range)

      raise RuntimeError.new("No data for dates provided") if delivery_attempts.empty?

      path = "#{Rails.root}/tmp/delivery_attempt_time_#{@start_date}_to_#{@end_date}.csv".delete(" ")
      csv_headers = ["created_at", "updated_at", "time delay(s)"]
      times = []

      CSV.open(path, "wb", headers: csv_headers, write_headers: true) do |csv|
        puts "Calculating delivery attempt times..."

        delivery_attempts.each do |delivery_attempt|
          time_delay = delivery_attempt.updated_at - delivery_attempt.created_at
          times << time_delay

          csv << [
            delivery_attempt.updated_at,
            delivery_attempt.created_at,
            time_delay,
          ]
        end
      end

      average_time = times.sum / times.length
      puts "Finished! Average delivery attempt time between #{start_date} and #{end_date} is #{average_time}s"
      puts "Report available at #{path}"
    end

  private

    attr_reader :start_date, :end_date

    def parse_date(date)
      raise ArgumentError, "Date(s) entered need to be of date/time format" unless Time.zone.parse(date)

      Time.zone.parse(date)
    end

    def get_email_delivery_attempts(date_range)
      DeliveryAttempt
        .where(status: 1)
        .where("sent_at IS NOT NULL")
        .where(created_at: date_range)
    end
  end
end
