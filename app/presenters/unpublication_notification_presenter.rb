
  class UnsubscriptionNotificationPresenter
    include Callable

    EMAIL_DATE_FORMAT = "%l:%M%P, %-d %B %Y".freeze

    def initialize(content_item, notification_template)
      @content_item = content_item
      @alternative_url = content_item["alternative_url"]
      @notification_template = notification_template
    end

    def call
      [
        page_summary,
        change_made,
        time_updated
      ].compact.join("\n\n")
    end

  private

  attr_reader :notification_template, :alternative_url

    def page_summary
      <<~PAGE_SUMMARY
        Page summary:
        #{page_summary_content}
      PAGE_SUMMARY
    end

    def change_made
      <<~CHANGE_MADE
        Change made:
        #{change_made_content}
      CHANGE_MADE
    end

    def time_updated
      if published_in_error?
        <<~TIME_UPDATED
          Time:
          #{time_updated_content}
        TIME_UPDATED
      end
    end

    def published_in_error?
      [
        :publish_in_error_no_url,
        :publish_in_error_alt_url,
      ].include?(notification_template)
    end

    def provides_alternative_url?
      [
        :publish_in_error_alt_url,
        :page_consolidated
      ].include?(notification_template)
    end

    def change_made_content
      I18n.t(
        "emails.unpublication_notification.#{notification_template}.change_made",
        alternative_url: alternative_url
      )
    end

    def page_summary_content
      # @TODO
      # I'm not clear where this comes from.
      # in the content_change_presenter.rb L64 sees it processed as markdown.
      # However this comes from a content_change event. We're not processing those,
      # Instead we'd hoped to get everything we wanted fromt he content item.
      #
      # Will need to work out if we can get a similar summary from the content_item
      # Possibly by looking into where the change notification gets it from?
      #
      # If we passed it through on the content_item we could lose this method and
      # do something in the initalizer like: @page_summary_content = content_item.page_summary_content
    end

    def time_updated_content
      # @TODO, presumably off the content_item?
      # Must confirm that the content item will always have an appropraite value in the two cases:
      # - publish_in_error_no_url
      # - publish_in_error_alt_url
      # Note content_change_presenter#L42 here, might be useful:
      # content_change.public_updated_at.strftime(EMAIL_DATE_FORMAT).strip
      # have included EMAIL_DATE_FORMAT above
      #
      # If we passed it through on the content_item we could lose this method and
      # do something in the initalizer like: @page_summary_content = content_item.page_summary_content
    end
  end
