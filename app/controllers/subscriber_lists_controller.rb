class SubscriberListsController < ApplicationController
  def index
    subscriber_list = FindExactQuery.new(find_exact_query_params).exact_match
    if subscriber_list
      render json: subscriber_list.to_json
    else
      render json: { error: "Could not find the subscriber list" }, status: :not_found
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
      render json: { error: "Could not find the subcsriber list" }, status: :not_found
    end
  end

  def create
    subscriber_list = SubscriberList.create!(subscriber_list_params)
    render json: subscriber_list.to_json, status: :created
  end

private

  def subscriber_list_params
    title = params.fetch(:title)
    slug = (params[:slug] || slugify(title))

    find_exact_query_params.merge(
      title: title,
      slug: slug,
      url: params[:url],
      description: (params[:description] || ""),
      list_group_id: params[:list_group_id],
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
      slug: params[:gov_delivery_id],
    }
  end

  def slugify(title)
    slug = title.parameterize.truncate(255, omission: '', separator: '-')

    while SubscriberList.where(slug: slug).exists?
      slug = title.parameterize.truncate(242, omission: '', separator: '-')
      slug += "-#{SecureRandom.hex(5)}"
    end

    slug
  end
end
