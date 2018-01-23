class MatchedContentChange < ApplicationRecord
  belongs_to :content_change
  belongs_to :subscriber_list
end
