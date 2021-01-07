class DigestEmailBuilder < ApplicationBuilder
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
      body: body,
      subscriber_id: subscriber.id,
    )
  end

private

  attr_reader :content, :subscription, :subscriber_list, :subscriber

  def body
    <<~BODY
      #{I18n.t("emails.digests.#{subscription.frequency}.opening_line")}

      #{title_and_optional_url}

      ---

      #{presented_results}

      ---

      #{FooterPresenter.call(subscriber, subscription)}
    BODY
  end

  def presented_results
    changes = content.map do |item|
      presenter = "#{item.class.name}Presenter".constantize
      presenter.call(item, frequency: subscription.frequency)
    end

    changes.join("\n\n---\n\n").strip
  end

  def title_and_optional_url
    result = "# " + subscriber_list.title

    source_url = SourceUrlPresenter.call(
      subscriber_list.url,
      utm_source: subscriber_list.slug,
      utm_content: subscription.frequency,
    )

    result += "\n\n" + source_url if source_url
    result
  end
end
