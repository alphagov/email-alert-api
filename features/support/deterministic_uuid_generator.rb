class DeterministicUUIDGenerator
  def initialize
    @count = 0
  end

  def call
    fixtures.fetch(@count) { raise "Ran out of UUIDS" }
  end

  def reset!
    @count = 0
  end

  def fixtures
    [
      "447135c3-07d6-4c3a-8a3b-efa49ef70e52",
      "21601a29-d335-4fb1-97c4-5c4c9059aa58",
      "51249842-c4c3-4fbe-af12-3aa8b8dfc940",
      "1f7c12b7-1633-4096-bc3b-be0995869658",
      "e1c8094d-9d22-457a-a301-48edc2df0c41",
      "7bb5576a-bacb-46ae-9acb-61ded7b61329",
      "80b067a4-ab17-48b5-bfee-a3d69bbc9189",
      "ce696f51-c77b-4e06-a04f-ffe9adcc5fad",
      "7573499a-f8b7-430c-b1b9-de61d9735014",
      "04201021-bac9-4dd6-9b67-8018589af4f6",
    ]
  end
end
