require 'rails_helper'
class NotificationHandler
  def self.call(params)
    notification = Notification.create(params)

    email = Email.create(some_params)

    (Matcher/Deliverer).perform_async(notification.id, email.id)
  end
end
