class LinksValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, links)
    invalidly_formatted = invalid_formatted_links(links)
    if invalidly_formatted.any?
      record.errors.add(attribute, "#{invalidly_formatted.to_sentence} has a value with an invalid format.")
    end
  end

private

  def invalid_formatted_links(links)
    invalid = links.select do |_key, link_values|
      link_values.flat_map(&:last)
        .any? { |link| !link.to_s.match?(/\A[a-zA-Z0-9\-_]*\z/) }
    end

    invalid.keys
  end
end
