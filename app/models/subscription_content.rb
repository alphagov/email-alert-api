class SubscriptionContent < ApplicationRecord
  belongs_to :subscription
  belongs_to :content_change, optional: true
  belongs_to :message, optional: true
  belongs_to :digest_run_subscriber, optional: true
  belongs_to :email, optional: true

  scope :immediate, -> { where(digest_run_subscriber_id: nil) }
  scope :digest, -> { where.not(digest_run_subscriber_id: nil) }

  validate :presence_of_content_change_or_message

  def presence_of_content_change_or_message
    has_content_change = content_change_id.present? || content_change.present?
    has_message = message_id.present? || message.present?

    if has_content_change && has_message
      errors.add(:base, "cannot be associated with a content_change and a message")
    end

    if !has_content_change && !has_message
      errors.add(:base, "must be associated with a content_change or a message")
    end
  end

  # This method is needed whilst we continue using Postgres 9.4, from 9.5
  # Postgres can suppoort a ON CONFLICT DO NOTHING and this can be called
  # directly through activerecord-import: https://github.com/zdennis/activerecord-import#duplicate-key-ignore
  def self.import_ignoring_duplicates(columns, rows, batch_size: 500)
    rows.each_slice(batch_size).to_a.each do |batch|
      transaction { import!(columns, batch) }
    rescue ActiveRecord::RecordNotUnique
      batch.each do |data|
        attributes = columns.zip(data).to_h
        create!(attributes) unless exists?(attributes)
      end
    end
  end
end
