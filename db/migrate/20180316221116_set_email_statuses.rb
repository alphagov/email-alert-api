class SetEmailStatuses < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    sent_emails.update_all(status: :sent)
    permanent_failure_emails.update_all(
      status: :failed,
      failure_reason: :permanent_failure,
    )
    # retries_exhausted_failure_emails.update_all(
    #   status: :failed,
    #   failure_reason: :retries_exhausted_failure,
    # )
    pending_emails.update_all(status: :pending)
  end

  def sent_emails
    query = DeliveryAttempt
      .where(status: :delivered)
      .where("email_id = emails.id")

    Email
      .where(status: nil)
      .where("EXISTS(#{query.to_sql})")
  end

  def permanent_failure_emails
    query = DeliveryAttempt
      .where(status: :permanent_failure)
      .where("email_id = emails.id")

    Email
      .where(status: nil)
      .where("EXISTS(#{query.to_sql})")
  end

  # def retries_exhausted_failure_emails
  #   query = DeliveryAttempt
  #     .where(status: :retries_exhausted_failure)
  #     .where("email_id = emails.id")
  #
  #   Email
  #     .where(status: nil)
  #     .where("EXISTS(#{query.to_sql})")
  # end

  def pending_emails
    # statuses = %w[delivered permanent_failure retries_exhausted_failure]
    statuses = %w[delivered permanent_failure]
    query = DeliveryAttempt
      .where(status: statuses)
      .where("email_id = emails.id")

    Email
      .where(status: nil)
      .where("NOT EXISTS(#{query.to_sql})")
  end
end
