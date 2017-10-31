require "rails_helper"

RSpec.describe Services do
  context "when config specifies NOTIFY as the email provider" do
    let(:services) { Services.clone }

    it "returns an instance of the notify sender" do
      expect(EmailAlertAPI.config)
        .to receive(:email_service_provider)
        .and_return("NOTIFY")

      expect(services.email_sender)
        .to be_an_instance_of(EmailSender::Notify)
    end
  end

  context "when config specifies PSEUDO as the email provider" do
    let(:services) { Services.clone }

    it "returns an instance of the pseudo sender" do
      expect(EmailAlertAPI.config)
        .to receive(:email_service_provider)
        .twice
        .and_return("PSEUDO")

      expect(services.email_sender)
        .to be_an_instance_of(EmailSender::Pseudo)
    end

    context "when config returns `nil` as the email provider" do
      let(:services) { Services.clone }

      it "returns an instance of the pseudo sender" do
        expect(EmailAlertAPI.config)
          .to receive(:email_service_provider)
          .thrice
          .and_return(nil)

        expect(services.email_sender)
          .to be_an_instance_of(EmailSender::Pseudo)
      end
    end

    context "when config returns an email provider we do not recognise" do
      let(:services) { Services.clone }

      it "returns an instance of the pseudo sender" do
        expect(EmailAlertAPI.config)
          .to receive(:email_service_provider)
          .exactly(4).times
          .and_return("UNRECOGNISED")

        expect { services.email_sender }
          .to raise_error("Email service provider UNRECOGNISED does not exist")
      end
    end
  end
end
