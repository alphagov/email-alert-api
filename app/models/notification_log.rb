class NotificationLog < ApplicationRecord
  # As JSON fields don't offer a matching comparitor in postgres
  # 9.3 we need to convert the fields to `text` in order to compare
  # them or use them in group clauses.
  # In order to compare/group the gov_delivery_id field it is necessary to
  # convert it to a `text` value first. For this reason we are sorting the data
  # as it's written in so that the text values can be correctly matched.
  # as '["aaaa","bbbb"]' != '["bbbb","aaaa"]'
  def gov_delivery_ids=(vals)
    super vals.sort
  end
end
