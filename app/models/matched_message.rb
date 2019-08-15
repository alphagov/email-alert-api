class MatchedMessage < ApplicationRecord
  belongs_to :message
  belongs_to :subscriber_list
end
