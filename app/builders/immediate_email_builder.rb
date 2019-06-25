class ImmediateEmailBuilder
  include EmailBuilderHelper
  def initialize(recipients_and_content)
    @recipients_and_content = recipients_and_content
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :recipients_and_content

  def records
    recipients_and_content.map do |recipient_and_content|
      [
        address = recipient_and_content.fetch(:address),
        subject(recipient_and_content.fetch(:content_change)),
        body(recipient_and_content.fetch(:content_change), recipient_and_content.fetch(:subscriptions), address),
        recipient_and_content.fetch(:subscriber_id),
      ]
    end
  end

  def columns
    %i(address subject body subscriber_id)
  end

  def body(content_change, subscriptions, address)
    if Array(subscriptions).empty?
      <<~BODY
        #{opening_line}

        #{presented_content_change(content_change)}
        ---
        #{feedback_link.strip}
      BODY
    else
      <<~BODY
        #{opening_line}

        #{presented_content_change(content_change)}
        ---
        #{permission_reminder(subscriptions.first.subscriber_list.title)}

        #{presented_unsubscribe_links(subscriptions)}
        #{presented_manage_subscriptions_links(address)}

        &nbsp;

        #{feedback_link.strip}
      BODY
    end
  end

  def presented_unsubscribe_links(subscriptions)
    links_array = subscriptions.map do |subscription|
      presented_unsubscribe_link(subscription.id, subscription.subscriber_list.title)
    end

    links_array.join("\n")
  end
end
