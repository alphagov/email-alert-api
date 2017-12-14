class Healthcheck
  def status
    if statuses.include?(:critical)
      :critical
    elsif statuses.include?(:warning)
      :warning
    else
      :ok
    end
  end

  def details
    { checks: checks }
  end

private

  def checks
    all.each.with_object({}) do |check, hash|
      hash[check.name] = check.details.merge(status: check.status)
    end
  end

  def statuses
    @statuses ||= all.map(&:status)
  end

  def all
    @all ||= [
      DatabaseHealthcheck.new,
      GovdeliveryHealthcheck.new,
      QueueLatencyHealthcheck.new,
      QueueSizeHealthcheck.new,
      RedisHealthcheck.new,
      RetrySizeHealthcheck.new,
      StatusUpdateHealthcheck.new,
      TechnicalFailureHealthcheck.new,
    ]
  end
end
