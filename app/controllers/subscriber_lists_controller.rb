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
    gov_delivery_id = if params[:gov_delivery_id].present?
      params[:gov_delivery_id]
    else
      gov_delivery_response = Services.gov_delivery.create_topic(params[:title])
      gov_delivery_response.to_param
    end

    SubscriberList.build_from(
      params: subscriber_list_params,
      gov_delivery_id: gov_delivery_id
    )
  end

  def find_subscriber_list
    FindExactQuery.new(subscriber_list_params.except(:title, :enabled)).exact_match
  end

  def subscriber_list_params
    {
      title: params[:title],
      tags: params.fetch(:tags, {}),
      links: params.fetch(:links, {}),
      document_type: params.fetch(:document_type, ""),
      enabled: params[:gov_delivery_id].blank?,
      email_document_supertype: params.fetch(:email_document_supertype, ""),
      government_document_supertype: params.fetch(:government_document_supertype, "")
    }
  end
end
