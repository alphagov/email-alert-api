RSpec.describe NotifyProvider do
  let(:template_id) { EmailAlertAPI.config.notify.fetch(:template_id) }

  it "calls the Notifications client" do
    allow(Notifications::Client).to receive(:new).and_return(client = double)

    expect(client).to receive(:send_email)
      .with(
        email_address: "email@address.com",
        template_id: template_id,
        reference: "ref-123",
        personalisation: {
          subject: "subject",
          body: "body",
        },
      )

    described_class.call(
      address: "email@address.com",
      subject: "subject",
      body: "body",
      reference: "ref-123",
    )
  end
end
