class SubscriberListsController < ApplicationController
  def index
    subscriber_list = FindExactQuery.new(**find_exact_query_params).exact_match
    if subscriber_list
      render json: subscriber_list.to_json
    else
      render json: { error: "Could not find the subscriber list" }, status: :not_found
    end
  end

  def show
    subscriber_list = SubscriberList.find_by(slug: params[:slug])
    if subscriber_list
      render(
        json: { subscriber_list: subscriber_list.attributes },
        status: status,
      )
    else
      render json: { error: "Could not find the subscriber list" }, status: :not_found
    end
  end

  def create
    subscriber_list = CreateSubscriberListService.call(params: params, user: current_user)
    render json: subscriber_list.to_json
  end

private

  def convert_legacy_params(link_or_tags)
    link_or_tags.transform_values do |link_or_tag|
      link_or_tag.is_a?(Hash) ? link_or_tag : { any: link_or_tag }
    end
  end

  def find_exact_query_params
    {
      tags: convert_legacy_params(params.permit(tags: {}).to_h.fetch(:tags, {})),
      links: convert_legacy_params(params.permit(links: {}).to_h.fetch(:links, {})),
      document_type: params.fetch(:document_type, ""),
      email_document_supertype: params.fetch(:email_document_supertype, ""),
      government_document_supertype: params.fetch(:government_document_supertype, ""),
    }
  end
end
