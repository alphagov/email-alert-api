class NotificationLog < ActiveRecord::Base
  validates :emailing_app, presence: true
end
