class DigestEmailBuilder
  include Callable

  def initialize(content:, subscription:)
    @content = content
    @subscription = subscription
    @subscriber = subscription.subscriber
    @subscriber_list = subscription.subscriber_list
  end

  def call
    Email.create!(
      address: subscriber.address,
      subject: I18n.t!(
        "emails.digests.#{subscription.frequency}.subject",
        title: subscriber_list.title,
      ),
      body:,
      subscriber_id: subscriber.id,
    )
  end

private

  attr_reader :content, :subscription, :subscriber_list, :subscriber

  def body
    <<~BODY
      #{I18n.t("emails.digests.#{subscription.frequency}.opening_line")}

      # #{subscriber_list.title}

      ---

      #{presented_results}

      ---

      #{FooterPresenter.call(subscriber, subscription)}
    BODY
  end

  def presented_results
    changes = content.map do |item|
      presenter = "#{item.class.name}Presenter".constantize
      presenter.call(item, subscription)
    end

    changes.join("\n\n---\n\n").strip
  end
end
