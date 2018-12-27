RSpec.describe Reports::ContentChangeEmailFailures do
  before do
    failure_reasons = %w[permanent_failure retries_exhausted_failure]

    3.times { create(:email, status: 'sent') }
    3.times do
      create(:email,
             status: 'failed',
             failure_reason: failure_reasons.sample)
    end
  end

  context 'generate report' do
    let(:content_change) { create(:content_change) }

    let(:sent)    { Email.where(status: 'sent') }
    let(:failed)  { Email.where(status: 'failed') }

    let(:failure_one)   { failed[0] }
    let(:failure_two)   { failed[1] }
    let(:failure_three) { failed[2] }

    let(:emails) { [sent, failed].flatten }

    let!(:subscription_contents) do
      emails.each do |email|
        create(:subscription_content,
               email: email,
               content_change: content_change)
      end
    end

    it 'produces a count of emails statuses for a given content change' do
      described_class.call(content_change)
      expect { described_class.call(content_change) }
        .to output(
          <<~TEXT
            #{failed.count} Email failures for Content Change #{content_change.id}
            -------------------------------------------

            Email Id:       #{failure_one.id}
            Failure Reason: #{failure_one.failure_reason}

            -------------------------------------------

            Email Id:       #{failure_two.id}
            Failure Reason: #{failure_two.failure_reason}

            -------------------------------------------

            Email Id:       #{failure_three.id}
            Failure Reason: #{failure_three.failure_reason}

            -------------------------------------------

          TEXT
        ).to_stdout
    end
  end
end
