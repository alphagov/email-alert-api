class StringParamValidator
  def initialize(param)
    @param = param
  end

  def valid?
    non_empty_string?(param)
  end

private
  attr_reader :param

  def non_empty_string?(test_value)
    test_value.is_a?(String) && !test_value.empty?
  end
end
