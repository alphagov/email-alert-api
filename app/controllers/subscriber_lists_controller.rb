require "gov_delivery/client"

class SubscriberListsController < ApplicationController
  before_filter :validate_request, only: :create

  def show
    subscriber_list = SubscriberList.where_tags_equal(params[:tags]).first

    if subscriber_list
      render json: subscriber_list.to_json
    else
      render json: {message: "Could not find the subscriber list"}, status: 404
    end
  end

  def create
    list = create_or_sync_subscriber_list

    if list.save
      render json: list.to_json, status: 201
    else
      render json: {message: "Couldn't create the subscriber list"}, status: 422
    end
  end

private
  def create_or_sync_subscriber_list
    gov_delivery = EmailAlertAPI.services(:gov_delivery)

    begin
      response = gov_delivery.create_topic(params[:title])
    rescue GovDelivery::Client::TopicAlreadyExistsError
      response = gov_delivery.read_topic_by_name(params[:title])
    end

    SubscriberList.new(
      title: params[:title],
      gov_delivery_id: response.to_param,
      tags: params[:tags]
    )
  end

  def validate_request
    params[:tags].each do |key, value|
      unless value.is_a?(Array)
        render json: {message: "All tag values must be sent as Arrays"}, status: 422
      end
    end
  end
end
