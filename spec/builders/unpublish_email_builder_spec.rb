RSpec.describe UnpublishEmailBuilder do
  describe ".call" do
    describe "No emails sent" do
      it "does not return any emails" do
        expect(described_class.call([], "body")).to be_empty
      end
      it "does not save and email objects" do
        expect { described_class.call([], "body") }.to_not(change { Email.count })
      end
    end

    describe "One email sent" do
      let!(:subscriber) do
        create(
          :subscriber,
          address: "address@test.com",
          id: 123,
        )
      end
      let(:emails) do
        [
          EmailParameters.new(
            subscriber: subscriber,
            subject: "subject_test",
            template_data: {
              redirect: redirect,
              utm_parameters: {
                "utm_source" => "mysource",
                "utm_content" => "mycontent",
              },
            },
          ),
        ]
      end
      let(:redirect) do
        double(:redirect, path: "/somewhere", title: "redirect_title", url: "https://redirect.to/somewhere")
      end
      it "Saves an email object" do
        expect { described_class.call(emails, "body") }.to change { Email.count }.by(1)
      end
      describe "return one email" do
        it "sets the subject" do
          imported_email = Email.find(described_class.call(emails, "body").first)
          expect(imported_email.subject).to eq("Update from GOV.UK – subject_test")
        end
        it "contains the subscriber id" do
          imported_email = Email.find(described_class.call(emails, "body").first)
          expect(imported_email.subscriber_id).to eq(123)
        end
        it "sets the status" do
          imported_email = Email.find(described_class.call(emails, "body").first)
          expect(imported_email.status).to eq("pending")
        end
        it "sets the addess" do
          imported_email = Email.find(described_class.call(emails, "body").first)
          expect(imported_email.address).to eq("address@test.com")
        end
        it "contains the body for the regular email" do
          imported_email = Email.find(described_class.call(emails, "body").first)
          expect(imported_email.body).to eq("body")
        end
        it "contains the redirect url in the body" do
          imported_email = Email.find(described_class.call(emails, "<%=redirect.url%>").first)
          expect(imported_email.body).to eq("https://redirect.to/somewhere")
        end
        it "contains the redirect title in the body" do
          imported_email = Email.find(described_class.call(emails, "<%=redirect.title%>").first)
          expect(imported_email.body).to eq("redirect_title")
        end
        it "contains the UTM parameters in the body" do
          imported_email = Email.find(described_class.call(emails, "<%=add_utm(redirect.url, utm_parameters)%>").first)
          expect(imported_email.body).to include("utm_source=mysource", "utm_content=mycontent")
        end
      end
    end
  end
end
