class RemoveDescriptionsFromTravelAdvice < ActiveRecord::Migration[5.2]
  DESCRIPTION = "Find out about the changes to [travelling to Europe after Brexit](https://www.gov.uk/visit-europe-brexit).".freeze

  def change
    SubscriberList.where(description: DESCRIPTION).update_all(description: "")
  end
end
