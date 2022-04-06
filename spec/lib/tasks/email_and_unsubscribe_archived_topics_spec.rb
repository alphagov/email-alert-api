RSpec.describe "archived_topics" do
  describe "send_emails" do
    before do
      Rake::Task["archived_topics:email_and_unsubscribe"].reenable
    end
    let(:url) { ArchivedTopics.urls_to_redirect.first[:url] }
    let(:subs_list) { create(:subscriber_list, url: url) }

    let(:body) do
      <<~BODY
        You asked GOV.UK to email you when we add or update a page about:


        #{subs_list.title}

        This topic has been archived. You will not get any more emails about it.
      BODY
    end

    it "states the topic the emails are being sent to and a redirect URL" do
      expect { Rake::Task["archived_topics:email_and_unsubscribe"].invoke }.to output(include("Sending email for #{subs_list.url} (ID: #{subs_list.id})")).to_stdout and output(include("https://www.gov.uk")).to_stdout
    end

    it "outputs the check message by default" do
      expect { Rake::Task["archived_topics:email_and_unsubscribe"].invoke }.to output(include(body)).to_stdout and output(include("DRY RUN")).to_stdout
    end

    it "does not attempt to destroy list with dry_run true (default)" do
      expect { Rake::Task["archived_topics:email_and_unsubscribe"].invoke }.to_not output(include("Destroying subscription list #{subs_list.url} (ID: #{subs_list.id})")).to_stdout
    end

    it "will destroy list with dry_run true (default)" do
      expect { Rake::Task["archived_topics:email_and_unsubscribe"].invoke("run") }.to output(include("Destroying subscription list #{subs_list.url} (ID: #{subs_list.id})")).to_stdout
    end
  end
end
