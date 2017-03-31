class SubscriberListCreator
  attr_reader :record

  def initialize(params)
    @params = params
  end

  def save
    @record = SubscriberList.new(@params)
    return false unless @record.save

    # if the topic_id is passed in use the provided title.
    return true if @record.gov_delivery_id.present?

    title_append_string = " (#{@record.id})"
    @record.title = "#{@record.title[0..(254 - title_append_string.size)]}#{title_append_string}"
    gov_delivery_id = build_on_gov_delivery(@record)
    @record.gov_delivery_id = gov_delivery_id
    @record.save
  end

  def build_on_gov_delivery(record)
    gov_delivery_response = Services.gov_delivery.create_topic(record.title)
    gov_delivery_response.to_param
  end
end
