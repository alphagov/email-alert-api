require 'sidekiq/api'

class HealthcheckController < ActionController::Base
  def check
    respond_to do |format|
      format.json {
        render json: {
          checks: {
            queue_size: {
              queues: sidekiq_queues,
              status: queue_size_status
            },
            queue_age:  {
              queues: queue_latencies,
              status: queue_age_status
            },
            queue_retry_size: {
              status: queue_retry_size_status
            },
            govdelivery: {
              status: govdelivery_status
            },
          },
          status: status
        }
      }
    end
  end

private

  def status
    ActiveRecord::Base.connected? &&
      Sidekiq.redis_info ? 'ok' : 'critical'
  end

  def govdelivery_status
    if Services.gov_delivery.ping.status == 200
      'ok'
    else
      'critical'
    end
  end

  def queue_retry_size_status
    sidekiq_retry_size = sidekiq_stats.retry_size
    case
    when sidekiq_retry_size >= ENV.fetch('SIDEKIQ_RETRY_SIZE_CRITICAL').to_i
      'critical'
    when sidekiq_retry_size >= ENV.fetch('SIDEKIQ_RETRY_SIZE_WARNING').to_i
      'warning'
    else
      'ok'
    end
  end

  def queue_size_status
    queues = sidekiq_queues
    case
    when queues.values.any? { |v| v >= ENV.fetch('SIDEKIQ_QUEUE_SIZE_CRITICAL').to_i }
      'critical'
    when queues.values.any? { |v| v >= ENV.fetch('SIDEKIQ_QUEUE_SIZE_WARNING').to_i }
      'warning'
    else
      'ok'
    end
  end

  def queue_age_status
    queue_age = queue_latencies
    case
    when queue_age.values.any? { |v| v >= ENV.fetch('SIDEKIQ_QUEUE_LATENCY_CRITICAL').to_i }
      'critical'
    when queue_age.values.any? { |v| v >= ENV.fetch('SIDEKIQ_QUEUE_LATENCY_WARNING').to_i }
      'warning'
    else
      'ok'
    end
  end

  def sidekiq_stats
    Sidekiq::Stats.new
  end

  def sidekiq_queues
    sidekiq_stats.queues
  end

  def queue_latencies
    sidekiq_queues.keys.inject({}) do |memo, queue|
      memo[queue] = Sidekiq::Queue.new(queue).latency
      memo
    end
  end
end
