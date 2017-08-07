class TopicMatchesController < ApplicationController
  def show
    respond_to do |format|
      format.json { render json: topic_matches }
    end
  end

private

  def topic_matches
    hash = params.permit!.to_h

    query = SubscriberListQuery.new(
      tags: hash[:tags] || {},
      links: hash[:links] || {},
      document_type: hash[:document_type],
      email_document_supertype: hash[:email_document_supertype],
      government_document_supertype: hash[:government_document_supertype],
    )

    topics = query.lists
    enabled, disabled = topics.partition(&:enabled?)

    {
      topics: topics.map(&:gov_delivery_id),
      enabled: enabled.map(&:gov_delivery_id),
      disabled: disabled.map(&:gov_delivery_id),
    }
  end
end
