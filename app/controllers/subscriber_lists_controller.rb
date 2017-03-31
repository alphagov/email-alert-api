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
    creator = SubscriberListCreator.new(subscriber_list_params)
    if creator.save
      respond_to do |format|
        format.json { render json: creator.record.to_json, status: 201 }
      end
    else
      respond_to do |format|
        format.json { render json: {message: creator.record.errors.full_messages.to_sentence}, status: 422 }
      end
    end
  end

private

  def subscriber_list_params
    find_exact_query_params.merge(
      title: params[:title],
      enabled: params[:gov_delivery_id].blank?,
      # gov_uk_delivery migration fields. these can be removed once the migration is completed
      migrated_from_gov_uk_delivery: params[:gov_delivery_id].present?,
      created_at: params[:created_at],
    )
  end

  def find_exact_query_params
    {
      tags: params.fetch(:tags, {}),
      links: params.fetch(:links, {}),
      document_type: params.fetch(:document_type, ""),
      email_document_supertype: params.fetch(:email_document_supertype, ""),
      government_document_supertype: params.fetch(:government_document_supertype, ""),
      gov_delivery_id: params[:gov_delivery_id],
    }
  end
end
