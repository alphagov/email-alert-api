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
    gov_delivery_response = Services.gov_delivery.create_topic(
      params[:title],
      params[:short_name],
      params[:description]
    )
    SubscriberList.build_from(
      params: subscriber_list_params,
      gov_delivery_id: gov_delivery_response.to_param
    )
  end

  def find_subscriber_list
    links_query = SubscriberListQuery.new(query_field: :links)
    tags_query = SubscriberListQuery.new(query_field: :tags)
    document_type_query = SubscriberListQuery.new(query_field: :neither)

    links_query.find_exact_match_with(links, document_type).first ||
      tags_query.find_exact_match_with(tags, document_type).first ||
      document_type_query.where_only_document_type_matches(document_type).first
  end

  def subscriber_list_params
    params.slice(:title, :short_name, :description)
      .merge(tags: params.fetch(:tags, {}))
      .merge(links: params.fetch(:links, {}))
      .merge(document_type: params.fetch(:document_type, ""))
  end

  def links
    subscriber_list_params[:links]
  end

  def tags
    subscriber_list_params[:tags]
  end

  def document_type
    subscriber_list_params[:document_type]
  end
end
