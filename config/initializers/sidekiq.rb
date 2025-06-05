require "sidekiq/job_logger"

# Set strict args so we're ready for Sidekiq 7
Sidekiq.strict_args!

class ExperimentalJobLogger < Sidekiq::JobLogger
  def call(item, queue)
    start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
    @logger.info { "start item #{item} on queue #{queue}" } unless @skip

    yield

    Sidekiq::Context.add(:elapsed, elapsed(start))
    @logger.info { "done item #{item} on queue #{queue}" } unless @skip
  rescue Exception # rubocop:disable Lint/RescueException
    Sidekiq::Context.add(:elapsed, elapsed(start))
    @logger.info { "failed item #{item} on queue #{queue}" } unless @skip
    raise
  end
end

Sidekiq.configure_server do |config|
  config.logger.level = Rails.logger.level
  config.job_logger = ExperimentalJobLogger
end
