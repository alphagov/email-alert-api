class ImmediateEmailBuilder
  def initialize(subscriber:, content_change:)
    @subscriber = subscriber
    @content_change = content_change
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    {
      address: subscriber.address,
      subject: subject,
      body: body
    }
  end

private

  attr_reader :subscriber, :content_change

  def subject
    "GOV.UK Update - #{content_change.title}"
  end

  def body
    <<~BODY
      #{presented_content_change}
      ---

      #{unsubscribe_links}
    BODY
  end

  def presented_content_change
    ContentChangePresenter.call(content_change)
  end

  def unsubscribe_links
    links = subscriber.subscriptions.map do |subscription|
      UnsubscribeLinkPresenter.call(uuid: subscription.uuid, title: subscription.subscriber_list.title)
    end

    links.join("\n\n")
  end
end
