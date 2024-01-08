class SubscriberListsController < ApplicationController
  def index
    subscriber_list = FindExactQuery.new(**find_exact_query_params).exact_match
    if subscriber_list
      render json: subscriber_list.to_json
    else
      render json: { error: "Could not find the subscriber list" }, status: :not_found
    end
  end

  def show
    subscriber_list = SubscriberList.find_by(slug: params[:slug])
    if subscriber_list
      render(
        json: { subscriber_list: subscriber_list.attributes },
        status:,
      )
    else
      render json: { error: "Could not find the subscriber list" }, status: :not_found
    end
  end

  def metrics
    render(
      json: {
        subscriber_list_count: active_subscriber_count("/#{params[:path]}"),
        all_notify_count: all_notify_count("/#{params[:path]}"),
      },
    )
  end

  def active_subscriber_count(govuk_path)
    subscriber_list = SubscriberList.find_by(url: govuk_path)
    subscriber_list ? subscriber_list.subscriptions.active.count : 0
  end

  def all_notify_count(govuk_path)
    return 0 unless EmailCriteriaQuery.new(govuk_path:).call

    SubscriberListsByPathQuery.new(govuk_path:).call.sum { |l| l.subscriptions.active.count }
  end

  def create
    subscriber_list = CreateSubscriberListService.call(
      title: params.fetch(:title),
      url: params.fetch(:url, nil),
      matching_criteria: find_exact_query_params,
      user: current_user,
      description: params.fetch(:description, nil),
    )

    render json: subscriber_list.to_json
  end

  def update
    permitted_params = params.permit(updatable_parameters)

    if permitted_params.empty?
      render json: {
        error: "Must include at least one of: #{updatable_parameters.join(', ')}",
      }, status: :unprocessable_entity
      return
    end

    subscriber_list = SubscriberList.find_by(slug: params[:slug])

    unless subscriber_list
      render json: { error: "Could not find the subscriber list" }, status: :not_found
      return
    end

    subscriber_list.update!(permitted_params)
    render json: subscriber_list.to_json
  end

  def bulk_unsubscribe
    subscriber_list = SubscriberList.find_by(slug: params[:slug])

    if subscriber_list.nil?
      render json: { error: "Could not find the subscriber list" }, status: :not_found
    elsif bulk_unsubscribe_params[:body] && !bulk_unsubscribe_params[:sender_message_id]
      render json: { error: "Unprocessable entity" }, status: :unprocessable_entity
    elsif bulk_unsubscribe_already_requested?
      render json: { error: "Message already received" }, status: :conflict
    else
      BulkUnsubscribeListService.call(
        subscriber_list:,
        params: bulk_unsubscribe_params,
        user: current_user,
        govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      )

      render json: { message: "List queued for bulk unsubscription" }, status: :accepted
    end
  end

  def bulk_migrate
    unless bulk_migrate_params[:from_slug].present? && bulk_migrate_params[:to_slug].present?
      render json: {
        error: "Must provide slugs for source and destination subscriber lists",
      }, status: :unprocessable_entity
      return
    end

    source_list = SubscriberList.find_by(slug: bulk_migrate_params[:from_slug])
    destination_list = SubscriberList.find_by(slug: bulk_migrate_params[:to_slug])

    if source_list.nil?
      render json: { error: "Could not find source subscriber list" }, status: :not_found
    elsif destination_list.nil?
      render json: { error: "Could not find destination subscriber list" }, status: :not_found
    else
      BulkMigrateListWorker.perform_async(
        source_list.id,
        destination_list.id,
      )
      render json: { message: "List queued for bulk migration" }, status: :accepted
    end
  end

private

  def updatable_parameters
    %i[title description]
  end

  def convert_legacy_params(link_or_tags)
    link_or_tags.transform_values do |link_or_tag|
      link_or_tag.is_a?(Hash) ? link_or_tag : { any: link_or_tag }
    end
  end

  def find_exact_query_params
    {
      content_id: params.fetch(:content_id, nil),
      tags: convert_legacy_params(params.permit(tags: {}).to_h.fetch(:tags, {})),
      links: convert_legacy_params(params.permit(links: {}).to_h.fetch(:links, {})),
      document_type: params.fetch(:document_type, ""),
      email_document_supertype: params.fetch(:email_document_supertype, ""),
      government_document_supertype: params.fetch(:government_document_supertype, ""),
    }
  end

  def bulk_unsubscribe_params
    params.permit(:body, :sender_message_id)
  end

  def bulk_migrate_params
    params.permit(:from_slug, :to_slug)
  end

  def bulk_unsubscribe_already_requested?
    return unless bulk_unsubscribe_params[:sender_message_id]

    Message.exists?(sender_message_id: bulk_unsubscribe_params[:sender_message_id])
  end
end
