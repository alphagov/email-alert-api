RSpec.describe "archived_topics" do
  describe "send_emails" do
    before do
      Rake::Task["archived_topics:send_emails"].reenable
    end

    it "states the topic the emails are being sent to" do
      subs_list = create(:subscriber_list, :archived_topic)

      expect { Rake::Task["archived_topics:send_emails"].invoke }.to output(include("Sending email for #{subs_list.url} (ID: #{subs_list.id})")).to_stdout
    end
  end
end
