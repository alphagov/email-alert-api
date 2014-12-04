require 'sidekiq/api'

class HealthcheckController < ActionController::Base
  def check
    render json: {
      checks: {
        queue_size: {
          status: queue_size_status
        },
        queue_age:  {
          status: queue_age_status
        }
      },
      status: 'ok' #FIXME: probably need to pin this on DB connectivity and
                   #Redis connectivity
    }
  end

private

  def queue_size_status
    queue_size_count = queue_size
    case
    when queue_size_count < 2
      'ok'
    when queue_size_count < 5
      'warning'
    else
      'critical'
    end
  end

  def queue_age_status
    queue_age_seconds = queue_age
    case
    when queue_age_seconds <= 30
      'ok'
    when queue_age_seconds <= 60
      'warning'
    else
      'critical'
    end
  end

  def queue_size
    Sidekiq::Queue.new('default').size
  end

  def queue_age
    Sidekiq::Queue.new('default').latency
  end
end
