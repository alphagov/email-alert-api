class AbsolutePathValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_path?(value)
      record.errors.add(attribute, "must be an absolute path")
    end
  end

private

  def valid_path?(path)
    parsed = URI.parse(path)
    parsed.relative? && path[0] == "/"
  rescue URI::InvalidURIError
    false
  end
end
