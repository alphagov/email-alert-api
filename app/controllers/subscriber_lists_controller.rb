require "gov_delivery/client"

class SubscriberListsController < ApplicationController
  before_filter :validate_request, only: :create

  def show
    subscriber_list = SubscriberList.where_tags_equal(params[:tags]).first

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
    list = build_subscriber_list
    if list.save
      respond_to do |format|
        format.json { render json: list.to_json, status: 201 }
      end
    else
      respond_to do |format|
        format.json { render json: {message: "Couldn't create the subscriber list"}, status: 422 }
      end
    end
  end

private
  def build_subscriber_list
    gov_delivery_response = Services.gov_delivery.create_topic(params[:title])
    SubscriberList.build_from(params: params, gov_delivery_id: gov_delivery_response.to_param)
  end

  def validate_request
    params[:tags].each do |key, value|
      unless value.is_a?(Array)
        render json: {message: "All tag values must be sent as Arrays"}, status: 422
      end
    end
  end
end
