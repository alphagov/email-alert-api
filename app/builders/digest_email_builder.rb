class DigestEmailBuilder
  def initialize(address:, subscription_content_changes:, digest_run:, subscriber_id:)
    @address = address
    @subscription_content_changes = subscription_content_changes
    @digest_run = digest_run
    @subscriber_id = subscriber_id
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.create!(
      address: address,
      subject: I18n.t!("emails.digests.#{digest_run.range}.subject"),
      body: body,
      subscriber_id: subscriber_id,
    )
  end

  private_class_method :new

private

  attr_reader :address, :subscription_content_changes, :digest_run, :subscriber_id

  def body
    <<~BODY
      #{I18n.t!("emails.digests.#{digest_run.range}.opening_line")}

      #{presented_results}
      #{I18n.t!("emails.digests.#{digest_run.range}.permission_reminder")}

      #{ManageSubscriptionsLinkPresenter.call(address)}

      #{feedback_link.strip}
    BODY
  end

  def presented_results
    subscription_content_changes.map { |content_change| presented_segment(content_change) }.join("\n&nbsp;\n\n")
  end

  def presented_segment(subscription_content_changes)
    <<~RESULT
      ##{subscription_content_changes.subscriber_list_title}&nbsp;

      #{deduplicate_and_present(subscription_content_changes.content_changes)}
      ---

      #{UnsubscribeLinkPresenter.call(subscription_content_changes.subscription_id, subscription_content_changes.subscriber_list_title)}
    RESULT
  end

  def deduplicate_and_present(content_changes)
    presented_content_changes(
      deduplicated_content_changes(content_changes)
    )
  end

  def deduplicated_content_changes(content_changes)
    ContentChangeDeduplicatorService.call(content_changes)
  end

  def presented_content_changes(content_changes)
    changes = content_changes.map do |content_change|
      ContentChangePresenter.call(content_change, frequency: digest_run.range)
    end

    changes.join("\n---\n\n")
  end

  def feedback_link
    I18n.t!("emails.feedback_link",
            survey_link: I18n.t!("emails.digests.#{digest_run.range}.survey_link"),
            feedback_link: "#{Plek.new.website_root}/contact")
  end
end
