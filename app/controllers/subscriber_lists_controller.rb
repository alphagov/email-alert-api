require "gov_delivery/client"

class SubscriberListsController < ApplicationController
  def show
    subscriber_list = FindExactQuery.new(find_exact_query_params).exact_match
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
    subscriber_list = SubscriberList.new(subscriber_list_params)
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

  def subscriber_list_params
    find_exact_query_params.merge(
      title: params[:title],
      gov_delivery_id: gov_delivery_id,
    )
  end

  def find_exact_query_params
    permitted_params = params.permit!.to_h
    {
      tags: permitted_params.fetch(:tags, {}),
      links: permitted_params.fetch(:links, {}),
      document_type: permitted_params.fetch(:document_type, ""),
      email_document_supertype: permitted_params.fetch(:email_document_supertype, ""),
      government_document_supertype: permitted_params.fetch(:government_document_supertype, ""),
      gov_delivery_id: params[:gov_delivery_id],
    }
  end

  def gov_delivery_id
    Services.gov_delivery.create_topic(params[:title]).to_param
  end
end
