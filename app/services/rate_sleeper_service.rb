class RateSleeperService
  def initialize(jobs_per_second:)
    @jobs_per_second = jobs_per_second
  end

  def run
    duration = Benchmark.realtime do
      yield
    end
    duration_in_milliseconds = duration * 1000

    required_sleep_time = sleep_time_in_seconds(
      execution_time_in_milliseconds: duration_in_milliseconds
    )

    sleep(required_sleep_time) if required_sleep_time.positive?
  end

private

  attr_reader :jobs_per_second

  def sleep_time_in_seconds(execution_time_in_milliseconds:)
    minimum_duration_in_milliseconds = 1000 / jobs_per_second.to_d

    return 0 if execution_time_in_milliseconds >= minimum_duration_in_milliseconds

    sleep_in_milliseconds = (
      minimum_duration_in_milliseconds - execution_time_in_milliseconds
    )

    sleep_in_milliseconds.to_d / 1000
  end
end
