class TagsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, tags)
    unless tag_values_are_arrays(tags)
      record.errors.add(attribute, "All tag values must be sent as Arrays")
    end

    if invalid_tags(tags).any?
      record.errors.add(attribute, "#{invalid_tags(tags).to_sentence} are not valid tags.")
    end
  end

private

  def invalid_tags(tags)
    tags.keys - ValidTags::ALLOWED_TAGS
  end

  def tag_values_are_arrays(tags)
    tags.values.all? do |hash|
      hash.all? do |operator, values|
        %i[all any].include?(operator) && values.is_a?(Array)
      end
    end
  end
end
