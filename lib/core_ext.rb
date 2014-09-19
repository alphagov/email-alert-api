module HashExt
  def slice(*keys)
    select { |k, _v| keys.include?(k) }
  end

  def except(*keys)
    reject { |k, _v| keys.include?(k) }
  end
end

Hash.class_eval do
  include HashExt
end
