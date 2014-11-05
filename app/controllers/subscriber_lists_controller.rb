class SubscriberListsController < ApplicationController
  def show
    subscriber_list = SubscriberList.where_tags_equal(params[:tags]).first

    if subscriber_list
      render json: subscriber_list.to_json
    else
      render json: {message: "Could not find the subscriber list"}, status: 404
    end
  end

  def create
    gov_delivery = EmailAlertAPI.services(:gov_delivery)
    response = gov_delivery.create_topic(params[:title])

    list = SubscriberList.new(
      title: params[:title],
      gov_delivery_id: response.to_param,
      tags: params[:tags]
    )

    if list.save
      render json: list.to_json, status: 201
    else
      render json: {message: "Couldn't create the subscriber list"}, status: 422
    end
  end
end
