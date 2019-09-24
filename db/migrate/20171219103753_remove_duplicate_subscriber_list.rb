class RemoveDuplicateSubscriberList < ActiveRecord::Migration[5.1]
  def change
    # production & staging
    SubscriberList.where(
      title: "news stories related to UK Visas and Immigration and China",
      gov_delivery_id: "UKGOVUK_35116",
    ).delete_all

    # integration
    SubscriberList.where(
      title: "news stories related to UK Visas and Immigration and China",
      gov_delivery_id: "UKGOVUKDUP_35116",
    ).delete_all
  end
end
