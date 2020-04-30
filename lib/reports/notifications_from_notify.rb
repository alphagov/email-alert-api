module Reports
  class NotificationsFromNotify
    def initialize(config: EmailAlertAPI.config.notify, notify_client: EmailAlertAPI.config.notify_client)
      @client = notify_client
      @template_id = config.fetch(:template_id)
    end

    def self.call(*args)
      new.call(*args)
    end

    def call(reference)
      # reference is the DeliveryAttempt.id
      puts "Query Notify for emails with the reference #{reference}"

      response = @client.get_notifications(
        template_type: "email",
        reference: reference,
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

    attr_reader :client, :template_id
  end
end
