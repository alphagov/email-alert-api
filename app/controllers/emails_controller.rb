class EmailsController < ApplicationController
  def create
    email = Email.create!(
      address: params.require(:address),
      subject: params.require(:subject),
      body: params.require(:body),
    )

    SendEmailWorker.perform_async_in_queue(email.id, queue: :send_email_immediate)

    render json: { message: "Email has been queued for sending" }, status: :accepted
  end
end
