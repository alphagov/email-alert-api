class NotificationsFromNotify
  def initialize
    @client = Notifications::Client.new(Rails.application.secrets.notify_api_key)
  end

  def self.call(*args)
    new.call(*args)
  end

  def call(reference)
    puts "Query Notify for emails with the reference #{reference}"

    response = client.get_notifications(
      template_type: "email",
      reference:,
    )

    if response.is_a?(Notifications::Client::NotificationsCollection)
      if response.collection.count.zero?
        puts "No results found, empty collection returned"
      else
        response.collection.each do |notification|
          puts <<~TEXT
            -------------------------------------------
            Notification ID: #{notification.id}
            Status: #{notification.status}
            created_at: #{notification.created_at}
            sent_at: #{notification.sent_at}
            completed_at: #{notification.completed_at}
          TEXT
        end
      end
    else
      puts "No results found"
    end
  rescue Notifications::Client::RequestError => e
    puts "Returns request error #{e.code}, message: #{e.message}"
  end

private

  attr_reader :client
end
