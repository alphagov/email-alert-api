class SubscriberListsByCriteriaQuery
  def self.call(*args)
    new(*args).call
  end

  def initialize(initial_scope, criteria_rules)
    @initial_scope = initial_scope
    @criteria_rules = criteria_rules
  end

  def call
    all_of_rule(initial_scope, criteria_rules)
  end

  private_class_method :new

private

  attr_reader :initial_scope, :criteria_rules

  def rule_condition(scope, rule)
    return scope.where(id: rule[:id]) if rule[:id]
    return type_rule(scope, **rule) if rule[:type]
    return any_of_rule(scope, rule[:any_of]) if rule[:any_of]
    return all_of_rule(scope, rule[:all_of]) if rule[:all_of]

    raise "Invalid rule: #{rule.inspect}"
  end

  def all_of_rule(scope, rule_list)
    rule_list.inject(scope) do |accumulative_scope, rule|
      accumulative_scope.merge(rule_condition(scope, rule))
    end
  end

  def any_of_rule(scope, rule_list)
    or_scope = rule_condition(scope, rule_list.first)

    rule_list.drop(1).inject(or_scope) do |accumulative_scope, rule|
      accumulative_scope.or(rule_condition(scope, rule))
    end
  end

  def type_rule(scope, type:, key:, value:)
    hash_rule_to_scope = lambda do |field|
      # we only apply this rule to SubscriberList tagged to "any", it didn't seem
      # to make logical sense to apply this to "all" ones
      scope.where(
        ":value IN (SELECT json_array_elements(#{field}->:key->'any')::text)",
        key:,
        # Postgres returns a string in double quotes where other double quote
        # characters are escaped
        value: %("#{value.gsub('"', '\\"')}"),
      )
    end

    case type
    when "tag"
      hash_rule_to_scope.call("tags")
    when "link"
      hash_rule_to_scope.call("links")
    when "content_id"
      scope.where(content_id: value)
    else
      raise "Unexpected rule type: #{type}"
    end
  end
end
