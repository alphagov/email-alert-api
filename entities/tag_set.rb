class TagSet
  extend Forwardable
  def initialize(tag_hash)
    @tag_hash = tag_hash
  end

  def_delegators :to_h, :fetch

  def to_h
    tag_hash.reduce({}) { |result, (k,v)|
      result.merge(k => v.sort)
    }
  end
  alias_method :to_hash, :to_h

  private

  attr_reader(:tag_hash)
end
