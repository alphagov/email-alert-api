require "rake"
require "rails_helper"

RSpec.describe "report:report_brexit_subscriptions" do
  before :each do
    Rails.application.load_tasks
  end

  it "sends the header" do
    expect {
      Rake::Task["report:report_brexit_subscriptions"].execute
    }.to output("date,message_id,number of messages sent\n").to_stdout
  end
  it "outputs a message to the csv" do
    subscriber_list = FactoryBot.create(:subscriber_list)
    FactoryBot.create(:subscription, subscriber_list: subscriber_list)
    message = FactoryBot.create(:message)
    FactoryBot.create(:matched_message, subscriber_list: subscriber_list, message: message)

    expect {
      Rake::Task["report:report_brexit_subscriptions"].execute
    }.to output(/#{Regexp.quote(message.created_at.to_s)},#{Regexp.quote(message.id.to_s)},1$/).to_stdout
  end
  it "counts the number of emails sent" do
    number_of_emails_sent = 4
    subscriber_list = FactoryBot.create(:subscriber_list)
    FactoryBot.create_list(:subscription, number_of_emails_sent, subscriber_list: subscriber_list)
    message = FactoryBot.create(:message)
    FactoryBot.create(:matched_message, subscriber_list: subscriber_list, message: message)

    expect {
      Rake::Task["report:report_brexit_subscriptions"].execute
    }.to output(/,#{number_of_emails_sent}$/).to_stdout
  end
end
