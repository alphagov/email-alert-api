RSpec.describe ContentChangeEmailStatusCount do
  before do
    3.times { create(:email, status: 'sent') }
    2.times { create(:email, status: 'pending') }
    1.times { create(:email, status: 'failed') }
  end

  context 'generate report' do
    let(:content_change) { create(:content_change) }

    let(:sent)    { Email.where(status: 'sent') }
    let(:pending) { Email.where(status: 'pending') }
    let(:failed)  { Email.where(status: 'failed') }

    let(:emails) { [sent, pending, failed].flatten }

    let!(:subscription_contents) do
      emails.each do |email|
        create(:subscription_content, email: email, content_change: content_change)
      end
    end

    it 'produces a count of emails statuses for a given content change' do
      described_class.call(content_change)
      expect { described_class.call(content_change) }.to output(
        <<~TEXT
          -------------------------------------------
          Email status counts for Content Change #{content_change.id}
          -------------------------------------------

          Sent emails: #{sent.count}

          Pending emails: #{pending.count}

          Failed emails: #{failed.count}

          -------------------------------------------
        TEXT
      ).to_stdout
    end
  end
end
