class AddDescriptionsToTravelAdvice < ActiveRecord::Migration[5.2]
  COUNTRIES = %w(
    austria
    belgium
    bulgaria
    croatia
    cyprus
    czech-republic
    denmark
    estonia
    finland
    france
    germany
    greece
    hungary
    iceland
    ireland
    italy
    latvia
    liechtenstein
    lithuania
    luxembourg
    malta
    netherlands
    norway
    poland
    portugal
    romania
    slovakia
    slovenia
    spain
    sweden
    switzerland
  ).freeze

  DESCRIPTION = "Find out about the changes to [travelling to Europe after Brexit](https://www.gov.uk/visit-europe-brexit).".freeze

  def slugs
    COUNTRIES.map { |country| "#{country}-travel-advice" }
  end

  def up
    updated_count = SubscriberList.where(slug: slugs)
      .update_all(description: DESCRIPTION)
    raise "Not all travel advice updated." unless updated_count == COUNTRIES.count
  end

  def down
    SubscriberList.where(slug: slugs).update_all(description: "")
  end
end
