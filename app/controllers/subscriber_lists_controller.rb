require "gov_delivery/client"

class SubscriberListsController < ApplicationController
  def show
    subscriber_list = find_subscriber_list
    if subscriber_list
      respond_to do |format|
        format.json { render json: subscriber_list.to_json }
      end
    else
      respond_to do |format|
        format.json { render json: {message: "Could not find the subscriber list"}, status: 404 }
      end
    end
  end

  def create
    subscriber_list = build_subscriber_list
    if subscriber_list.save
      respond_to do |format|
        format.json { render json: subscriber_list.to_json, status: 201 }
      end
    else
      respond_to do |format|
        format.json { render json: {message: subscriber_list.errors.full_messages.to_sentence}, status: 422 }
      end
    end
  end

private
  def build_subscriber_list
    gov_delivery_response = Services.gov_delivery.create_topic(params[:title])
    SubscriberList.build_from(
      params: subscriber_list_params,
      gov_delivery_id: gov_delivery_response.to_param
    )
  end

  def find_subscriber_list
    match = SubscriberListQuery.new(query_field: :links).find_exact_match_with(subscriber_list_params[:links]).first
    return match if match.present?
    return SubscriberListQuery.new(query_field: :tags).find_exact_match_with(subscriber_list_params[:tags]).first
  end

  def subscriber_list_params
    params.slice(:title)
      .merge(tags: params.fetch(:tags, {}))
      .merge(links: params.fetch(:links, {}))
  end
end
