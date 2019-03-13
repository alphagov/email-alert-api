class SubscriberListsController < ApplicationController
  def index
    subscriber_list = FindExactQuery.new(find_exact_query_params).exact_match
    if subscriber_list
      render json: subscriber_list.to_json
    else
      render json: { message: "Could not find the subscriber list" }, status: 404
    end
  end

  def show
    subscriber_list = SubscriberList.find_by(slug: params[:slug])
    if subscriber_list
      render json: {
        subscribable: subscriber_list.attributes, # for backwards compatiblity
        subscriber_list: subscriber_list.attributes,
      }, status: status
    else
      render json: { message: "Could not find the subcsriber list" }, status: 404
    end
  end

  def create
    subscriber_list = SubscriberList.new(subscriber_list_params)
    if subscriber_list.save
      render json: subscriber_list.to_json, status: 201
    else
      render json: { message: subscriber_list.errors.full_messages.to_sentence }, status: 422
    end
  end

private

  def subscriber_list_params
    title = params.fetch(:title)
    slug = slugify(title)

    find_exact_query_params.merge(
      title: title,
      slug: slug,
      signon_user_uid: current_user.uid,
    )
  end

  def convert_legacy_params(link_or_tags)
    link_or_tags.transform_values do |link_or_tag|
      link_or_tag.is_a?(Hash) ? link_or_tag : { any: link_or_tag }
    end
  end

  def find_exact_query_params
    permitted_params = params.permit!.to_h
    {
      tags: convert_legacy_params(permitted_params.fetch(:tags, {})),
      links: convert_legacy_params(permitted_params.fetch(:links, {})),
      document_type: permitted_params.fetch(:document_type, ""),
      email_document_supertype: permitted_params.fetch(:email_document_supertype, ""),
      government_document_supertype: permitted_params.fetch(:government_document_supertype, ""),
      content_purpose_supergroup: permitted_params.fetch(:content_purpose_supergroup, nil),
      slug: params[:gov_delivery_id],
    }
  end

  def slugify(title)
    slug = title.parameterize
    index = 1

    while SubscriberList.where(slug: slug).exists?
      index += 1
      slug = "#{title.parameterize}-#{index}"
    end

    slug
  end
end
