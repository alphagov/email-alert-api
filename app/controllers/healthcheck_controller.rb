require 'sidekiq/api'

class HealthcheckController < ActionController::Base
  def check
    render json: {
      checks: {
        queue_size: queue_size,
        queue_age:  queue_age
      },
      status: 'ok' #FIXME: probably need to pin this on DB connectivity and
                   #Redis connectivity
    }
  end

private

  def queue_size
    Sidekiq::Queue.new('default').size
  end

  def queue_age
    Sidekiq::Queue.new('default').latency
  end
end
