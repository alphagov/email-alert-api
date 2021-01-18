class CreateSubscriberListService < ApplicationService
  def initialize(params:, user:)
    @params = params
    @user = user
  end

  def call
    subscriber_list = FindExactQuery.new(**find_exact_query_params).exact_match
    return SubscriberList.create!(subscriber_list_params) unless subscriber_list

    subscriber_list.update!(subscriber_list_params.slice(:title, :url).compact)
    subscriber_list
  end

private

  attr_reader :params, :user

  def subscriber_list_params
    find_exact_query_params.merge(
      title: params[:title],
      slug: slug,
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

  def slug
    @slug ||= begin
      result = params[:title].parameterize.truncate(255, omission: "", separator: "-")

      while SubscriberList.where(slug: result).exists?
        result = params[:title].parameterize.truncate(244, omission: "", separator: "-")
        result += "-#{SecureRandom.hex(5)}"
      end

      result
    end
  end
end
