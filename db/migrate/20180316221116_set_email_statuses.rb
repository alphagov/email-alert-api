class SetEmailStatuses < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    DeliveryAttempt
      .where(status: :delivered)
      .in_batches(of: 10_000)
      .each_with_index do |batch, index|
        puts "Processed #{10_000 * index} sent emails"
        Email.where(id: batch.pluck(:email_id)).update_all(status: :sent)
        sleep(0.1)
      end

    DeliveryAttempt
      .where(status: :permanent_failure)
      .in_batches(of: 10_000)
      .each_with_index do |batch, index|
        puts "Processed #{10_000 * index} failed emails"
        Email.where(id: batch.pluck(:email_id)).update_all(status: :failed, failure_reason: :permanent_failure)
        sleep(0.1)
      end

    pending = Email.where(status: nil).update_all(status: :pending)
    puts "#{pending} emails marked as pending"
  end
end
