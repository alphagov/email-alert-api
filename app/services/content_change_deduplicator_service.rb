class ContentChangeDeduplicatorService
  def self.call(*args)
    new.call(*args)
  end

  def call(content_changes)
    reverse_by_public_updated_at(content_changes)
      .uniq(&:content_id)
  end

  private_class_method :new

private

  def reverse_by_public_updated_at(content_changes)
    content_changes.sort do |cc_a, cc_b|
      cc_b.public_updated_at <=> cc_a.public_updated_at
    end
  end
end
