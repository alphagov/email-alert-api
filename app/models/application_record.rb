class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.try_lock
    transaction do
      lock("FOR UPDATE NOWAIT")
      yield
    rescue ActiveRecord::LockWaitTimeout => e
      Rails.logger.warn(e)
    end
  end
end
