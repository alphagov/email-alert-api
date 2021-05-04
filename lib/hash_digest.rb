require "digest"

class HashDigest
  def initialize(hash)
    @original_hash = hash.deep_symbolize_keys
  end

  def generate
    return nil if original_hash.empty?

    Digest::SHA256.hexdigest(sort_hash(original_hash).to_s)
  end

private

  attr_reader :original_hash

  # We sort the hash because the order of keys and values shouldn't matter.
  # You should get the same digest for a hash regardless of structure.
  def sort_hash(hash)
    value_sorted_hash = hash.transform_values do |value|
      case value
      when Hash
        sort_hash(value)
      when Array
        value.compact.sort
      else
        value
      end
    end

    value_sorted_hash.sort
  end
end
