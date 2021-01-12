class CreateSubscriberListService < ApplicationService
  def initialize(params:, user:)
    @params = params
    @user = user
  end

  def call
    SubscriberList.create!(subscriber_list_params)
  end

private

  attr_reader :params, :user

  def subscriber_list_params
    title = params.fetch(:title)

    find_exact_query_params.merge(
      title: title,
      slug: slugify(title),
      url: params[:url],
      signon_user_uid: user.uid,
    )
  end

  def convert_legacy_params(link_or_tags)
    link_or_tags.transform_values do |link_or_tag|
      link_or_tag.is_a?(Hash) ? link_or_tag : { any: link_or_tag }
    end
  end

  def find_exact_query_params
    {
      tags: convert_legacy_params(params.permit(tags: {}).to_h.fetch(:tags, {})),
      links: convert_legacy_params(params.permit(links: {}).to_h.fetch(:links, {})),
      document_type: params.fetch(:document_type, ""),
      email_document_supertype: params.fetch(:email_document_supertype, ""),
      government_document_supertype: params.fetch(:government_document_supertype, ""),
    }
  end

  def slugify(title)
    slug = title.parameterize.truncate(255, omission: "", separator: "-")

    while SubscriberList.where(slug: slug).exists?
      slug = title.parameterize.truncate(244, omission: "", separator: "-")
      slug += "-#{SecureRandom.hex(5)}"
    end

    slug
  end
end
