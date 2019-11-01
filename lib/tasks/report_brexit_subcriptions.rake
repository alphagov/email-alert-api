namespace :report do
  desc "Creates a spreadsheet with all the emails sent per Brexit update"
  task report_brexit_subscriptions: :environment do
    all_messages = Message.order(:created_at)
    counts = all_messages.all.map do |message|
      Subscription.active_on(message.created_at).
        joins(subscriber_list: :matched_messages).
        where("matched_messages.message_id" => message).count
    end

    CSV($stdout, headers: ["date", "message_id", "number of messages sent"], write_headers: true) do |csv|
      all_messages.zip(counts).each do |message, count|
        csv << [message.created_at, message.id, count]
      end
    end
  end
end
