class TagsParamValidator
  def initialize(tags)
    @tags = tags
  end

  def valid?
    non_empty_hash?(tags) && tag_keys_are_valid? && tag_values_are_valid?
  end

private
  attr_reader :tags

  def tag_keys_are_valid?
    tags.keys.all? { |key|
      non_empty_string?(key)
    }
  end

  def tag_values_are_valid?
    tags.values.all? { |tag_values|
      non_empty_array?(tag_values) && tag_values.all? { |value|
        non_empty_string?(value)
      }
    }
  end

  def non_empty_string?(test_value)
    test_value.is_a?(String) && !test_value.empty?
  end

  def non_empty_array?(test_value)
    test_value.is_a?(Array) && !test_value.empty?
  end

  def non_empty_hash?(test_value)
    test_value.is_a?(Hash) && !test_value.empty?
  end
end
