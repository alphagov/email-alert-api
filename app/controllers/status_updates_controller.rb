class StatusUpdatesController < ApplicationController
  wrap_parameters false

  def create
    status = params.require(:status)
    reference = params.require(:reference)

    logger.debug("Email #{reference} callback received with status: #{status}")
    GovukStatsd.increment("status_update.status.#{status}")

    # We are deliberatly omitting "technical-failure" as Notify say this is
    # not sent via callback. If we start receiving these we should chat to
    # Notify about why.
    unless %w[delivered permanent-failure temporary-failure].include?(status)
      error = "Recieved an unexpected status from Notify: '#{status}'"
      GovukError.notify(error)
      render json: { error: }, status: :unprocessable_entity
      return
    end

    if status == "permanent-failure"
      subscriber = Subscriber.find_by(address: params.require(:to))
      UnsubscribeAllService.call(subscriber, :non_existent_email) if subscriber
    end

    begin
      Email.find(reference).update!(notify_status: status)
    rescue StandardError
      # At the moment we don't want to do anything if
      # the reference can't be found.
    end

    head :no_content
  end

private

  def authorise
    authorise_user!("status_updates")
  end
end
