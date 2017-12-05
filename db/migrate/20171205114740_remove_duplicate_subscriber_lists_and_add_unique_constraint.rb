class RemoveDuplicateSubscriberListsAndAddUniqueConstraint < ActiveRecord::Migration[5.1]
  # List of SubscriberList with duplicates
  # - - 26
  #   - UKGOVUK_13446
  #   - :topics:
  #     - environmental-management/boating
  #   - :topics:
  #     - 5679543e-81eb-4737-8f33-64e4131fa753
  # - - 27
  #   - UKGOVUK_13446
  #   - :topics:
  #     - environmental-management/boating
  #   - :topics:
  #     - 5679543e-81eb-4737-8f33-64e4131fa753
  # - - 28
  #   - UKGOVUK_13446
  #   - :topics:
  #     - environmental-management/boating
  #   - :topics:
  #     - 5679543e-81eb-4737-8f33-64e4131fa753
  # - - 29
  #   - UKGOVUK_13446
  #   - :topics:
  #     - environmental-management/boating
  #   - :topics:
  #     - 5679543e-81eb-4737-8f33-64e4131fa753
    # KEEP THIS ONE
    # - - 30
    #   - UKGOVUK_13446
    #   - :topics:
    #     - environmental-management/boating
    #   - :topics:
    #     - 5679543e-81eb-4737-8f33-64e4131fa753
  # - - 43
  #   - UKGOVUK_16827
  #   - :topics:
  #     - business-tax/construction-industry-scheme
  #   - :topics:
  #     - 741f41c9-9083-48e2-bb9a-55b1649fc3bf
  # - - 45
  #   - UKGOVUK_16827
  #   - :topics:
  #     - business-tax/construction-industry-scheme
  #   - :topics:
  #     - 741f41c9-9083-48e2-bb9a-55b1649fc3bf
    # KEEP THIS ONE
    # - - 46
    #   - UKGOVUK_16827
    #   - :topics:
    #     - business-tax/construction-industry-scheme
    #   - :topics:
    #     - 741f41c9-9083-48e2-bb9a-55b1649fc3bf
  # - - 44
  #   - UKGOVUK_16830
  #   - :topics:
  #     - business-tax/employment-related-securities
  #   - :topics:
  #     - 27426f9e-8bd9-4785-aab5-5f8f1f9a470d
  # - - 48
  #   - UKGOVUK_16830
  #   - :topics:
  #     - business-tax/employment-related-securities
  #   - :topics:
  #     - 27426f9e-8bd9-4785-aab5-5f8f1f9a470d
    # KEEP THIS ONE
    # - - 49
    #   - UKGOVUK_16830
    #   - :topics:
    #     - business-tax/employment-related-securities
    #   - :topics:
    #     - 27426f9e-8bd9-4785-aab5-5f8f1f9a470d
  # - - 153
  #   - UKGOVUK_16938
  #   - :topics:
  #     - personal-tax/savings-investment-tax
  #   - :topics:
  #     - 11f92608-272a-4c96-8b24-e19a8c6da3bc
    # KEEP THIS ONE
    # - - 155
    #   - UKGOVUK_16938
    #   - :topics:
    #     - personal-tax/savings-investment-tax
    #   - :topics:
    #     - 11f92608-272a-4c96-8b24-e19a8c6da3bc
  def up
    duplicate_subscriber_list_ids = [26, 27, 28, 29, 43, 45, 44, 48, 153]
    SubscriberList.where(id: duplicate_subscriber_list_ids).destroy_all

    add_index :subscriber_lists, :gov_delivery_id, unique: true
  end
end
