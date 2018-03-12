class SubscriptionContentsImmediateInsert
  def initialize(content_change_id)
    @content_change_id = content_change_id
  end

  def self.call(content_change_id:)
    new(content_change_id).call
  end

  def call
    ActiveRecord::Base.connection.execute(
      sql
    )
  end

private

  attr_reader :content_change_id

  def sql
    date = Time.zone.now
    <<-SQL
      INSERT INTO
        subscription_contents(
          subscription_id,
          content_change_id,
          created_at,
          updated_at
        )
      SELECT
        subscriptions.id,
        uuid('#{content_change_id}'),
        '#{date}',
        '#{date}'
      FROM
        subscriptions
        INNER JOIN subscriber_lists
          ON subscriptions.subscriber_list_id = subscriber_lists.id
        INNER JOIN matched_content_changes
          ON subscriber_lists.id = matched_content_changes.subscriber_list_id
      WHERE
        matched_content_changes.content_change_id = uuid('#{content_change_id}')
    SQL
  end
end
