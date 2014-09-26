require "forwardable"

class MemoryStorageAdapter
  extend Forwardable
  def_delegators :storage, :store, :fetch

  def find_by(namespace, field, value)
    storage.select { |_id, data|
      data.fetch(field, nil) == value
    }
  end

  def storage
    @storage ||= {}
  end

  def clear
    @storage = {}
  end
end
