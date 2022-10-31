class UuidValidator < ActiveModel::EachValidator
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\Z/i

  def validate_each(record, attribute, value)
    unless UUID_REGEX =~ value
      record.errors.add(attribute, "is not a valid UUID")
    end
  end
end
