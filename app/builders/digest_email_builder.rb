class DigestEmailBuilder < ApplicationBuilder
  def initialize(address:, digest_item:, digest_run:, subscriber_id:)
    @address = address
    @digest_item = digest_item
    @digest_run = digest_run
    @subscriber_id = subscriber_id
  end

  def call
    Email.create!(
      address: address,
      subject: I18n.t!("emails.digests.#{digest_run.range}.subject"),
      body: body,
      subscriber_id: subscriber_id,
    )
  end

private

  attr_reader :address, :digest_item, :digest_run, :subscriber_id

  def body
    <<~BODY
      #{I18n.t!("emails.digests.#{digest_run.range}.opening_line")}

      #{presented_results}
      #{I18n.t!("emails.digests.#{digest_run.range}.permission_reminder")}

      #{ManageSubscriptionsLinkPresenter.call(address)}
    BODY
  end

  def presented_results
    presented_segment(digest_item)
  end

  def presented_segment(segment)
    <<~RESULT
      #{presented_header(segment)}

      #{presented_content(segment.content)}
      ---

      #{UnsubscribeLinkPresenter.call(segment.subscription_id, segment.subscriber_list_title)}
    RESULT
  end

  def presented_header(segment)
    copy = "# #{presented_title(segment)} &nbsp;"

    if segment.subscriber_list_description.present?
      copy += "\n\n#{segment.subscriber_list_description}"
    end

    copy
  end

  def presented_title(segment)
    if segment.subscriber_list_url
      "[#{segment.subscriber_list_title}](#{Plek.new.website_root}#{segment.subscriber_list_url})"
    else
      segment.subscriber_list_title
    end
  end

  def presented_content(content)
    changes = content.map do |item|
      case item
      when ContentChange
        ContentChangePresenter.call(item, frequency: digest_run.range)
      when Message
        MessagePresenter.call(item, frequency: digest_run.range)
      else
        raise "Unexpected content type: #{item.class}"
      end
    end

    changes.join("\n---\n\n")
  end
end
