class MatchedContentChange < ApplicationRecord
  # Any validations added this to this model won't be applied on record
  # creation as this table is populated by the #insert_all bulk method

  belongs_to :content_change
  belongs_to :subscriber_list
end
