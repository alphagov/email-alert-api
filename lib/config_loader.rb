require "yaml"
require "forwardable"

class ConfigLoader
  extend Forwardable

  def initialize(config_files)
    @config_files = config_files
  end

  hash_methods = Hash.instance_methods - Object.instance_methods

  def_delegators :to_h, *hash_methods

  def to_h
    @hash ||= symbolize_keys(config_hash)
  end

private
  attr_reader :config_files

  def config_hash
    config_files
      .map { |file_name| File.read(file_name) }
      .map { |yaml_string| YAML.load(yaml_string) }
      .reduce(&:merge)
  end

  def symbolize_keys(input)
    return input unless input.is_a?(Hash)

    input.reduce({}) { |result, (k, v)|
      result.merge(k.to_sym => symbolize_keys(v))
    }
  end
end
