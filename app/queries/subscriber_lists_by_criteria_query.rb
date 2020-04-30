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
    return type_rule(scope, rule) if rule[:type]
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
    field = case type
            when "tag" then "tags"
            when "link" then "links"
            else
              raise "Unexpected rule type: #{type}"
            end

    # we only apply this rule to SubscriberList tagged to "any", it didn't seem
    # to make logical sense to apply this to "all" ones
    scope.where(
      ":value IN (SELECT json_array_elements(#{field}->:key->'any')::text)",
      key: key,
      # Postgres returns a string in double quotes where other double quote
      # characters are escaped
      value: %("#{value.gsub('"', '\\"')}"),
    )
  end
end
