class RootRelativeUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_url?(value)
      record.errors.add(attribute, "must be a root-relative URL")
    end
  end

private

  def valid_url?(url)
    parsed = URI.parse(url)
    parsed.relative? && !parsed.host && url[0] == "/"
  rescue URI::InvalidURIError
    false
  end
end
