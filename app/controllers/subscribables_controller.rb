class SubscribablesController < ApplicationController
  def show
    render json: { subscribable: subscribable_attributes }, status: status
  end

private

  def subscribable
    @subscribable ||= SubscriberList.find_by(slug: params[:slug])
  end

  def subscribable_attributes
    subscribable.nil? ? nil : subscribable.attributes
  end

  def status
    subscribable.nil? ? 404 : 200
  end
end
