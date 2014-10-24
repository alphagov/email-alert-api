class SubscriberListsController < ApplicationController
  def create
    gov_delivery = EmailAlertAPI.services(:gov_delivery)
    response = gov_delivery.create_topic(name: params[:title])

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
