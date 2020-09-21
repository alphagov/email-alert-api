RSpec.describe ApplicationRecord do
  describe ".try_lock" do
    it "silently skips if the record is already being processed" do
      allow(ApplicationRecord).to receive(:lock).and_raise(ActiveRecord::LockWaitTimeout)
      duplicate_work_attempt = proc { ContentChange.try_lock { ContentChange.find(1) } }
      expect { duplicate_work_attempt.call }.to_not raise_error
    end
  end
end
