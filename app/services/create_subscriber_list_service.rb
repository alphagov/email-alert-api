class CreateSubscriberListService
  include Callable

  def initialize(title:, url:, matching_criteria:, user:, description: nil)
    @title = title
    @url = url
    @matching_criteria = matching_criteria
    @user = user
    @description = description
  end

  def call
    subscriber_list = FindExactQuery.new(**matching_criteria).exact_match
    return SubscriberList.create!(subscriber_list_params) unless subscriber_list

    subscriber_list.update!(title:, url:)
    subscriber_list
  end

private

  attr_reader :title, :url, :matching_criteria, :user, :description

  def subscriber_list_params
    matching_criteria.merge(
      title:,
      slug:,
      url:,
      signon_user_uid: user.uid,
      description:,
    )
  end

  def slug
    @slug ||= begin
      result = title.parameterize.truncate(255, omission: "", separator: "-")

      while SubscriberList.where(slug: result).exists?
        result = title.parameterize.truncate(244, omission: "", separator: "-")
        result += "-#{SecureRandom.hex(5)}"
      end

      result
    end
  end
end
