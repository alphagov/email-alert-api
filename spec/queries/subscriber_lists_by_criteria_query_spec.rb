RSpec.describe SubscriberListsByCriteriaQuery do
  describe ".call" do
    it "can match an ID" do
      list = create(:subscriber_list, tags: { format: { any: %w[match] } })
      create(:subscriber_list, tags: { format: { any: %w[no-match] } })

      result = described_class.call(
        SubscriberList,
        [
          { id: list.id },
        ],
      )

      expect(result).to contain_exactly(list)
    end

    it "can match a content_id" do
      uuid = SecureRandom.uuid
      list = create(:subscriber_list, content_id: uuid, tags: { format: { any: %w[match] } })

      result = described_class.call(
        SubscriberList,
        [
          { type: "content_id", key: "format", value: uuid.to_s },
        ],
      )

      expect(result).to contain_exactly(list)
    end

    it "raises error when an invalid rule" do
      rule = {
        none_of: [
          { type: "tag", key: "format", value: "match_a" },
        ],
      }

      expect {
        described_class.call(
          SubscriberList,
          [
            rule,
          ],
        )
      }.to raise_error(RuntimeError, "Invalid rule: #{rule.inspect}")
    end

    it "raises error when an invalid rule type" do
      expect {
        described_class.call(
          SubscriberList,
          [
            { type: "giraffe", key: "format", value: "1" },
          ],
        )
      }.to raise_error(RuntimeError, /Unexpected rule type: giraffe/)
    end

    it "can match a tag" do
      list = create(:subscriber_list, tags: { format: { any: %w[match] } })
      create(:subscriber_list, tags: { format: { any: %w[no-match] } })

      result = described_class.call(
        SubscriberList,
        [
          { type: "tag", key: "format", value: "match" },
        ],
      )

      expect(result).to contain_exactly(list)
    end

    it "can match a link" do
      uuid = SecureRandom.uuid
      list = create(:subscriber_list, links: { format: { any: [uuid] } })
      create(:subscriber_list, links: { format: { any: [SecureRandom.uuid] } })

      result = described_class.call(
        SubscriberList,
        [
          { type: "link", key: "format", value: uuid },
        ],
      )

      expect(result).to contain_exactly(list)
    end

    it "can match multiple tags" do
      list = create(:subscriber_list, tags: { format: { any: %w[match part_of_match] } })
      create(:subscriber_list, tags: { format: { any: %w[part_of_match] } })

      result = described_class.call(
        SubscriberList,
        [
          { type: "tag", key: "format", value: "match" },
          { type: "tag", key: "format", value: "part_of_match" },
        ],
      )

      expect(result).to contain_exactly(list)
    end

    it "can match tags and links" do
      uuid = SecureRandom.uuid
      list = create(
        :subscriber_list,
        tags: { format: { any: %w[match] } },
        links: { format: { any: [uuid] } },
      )
      create(:subscriber_list)

      result = described_class.call(
        SubscriberList,
        [
          { type: "tag", key: "format", value: "match" },
          { type: "link", key: "format", value: uuid },
        ],
      )

      expect(result).to contain_exactly(list)
    end

    it "can match optional conditions" do
      list_a = create(:subscriber_list, tags: { format: { any: %w[match_a] } })
      list_b = create(:subscriber_list, tags: { format: { any: %w[match_b] } })
      create(:subscriber_list)

      result = described_class.call(
        SubscriberList,
        [
          {
            any_of: [
              { type: "tag", key: "format", value: "match_a" },
              { type: "tag", key: "format", value: "match_b" },
            ],
          },
        ],
      )

      expect(result).to contain_exactly(list_a, list_b)
    end

    it "can match nested and conditions in or conditions" do
      list_a = create(:subscriber_list, tags: { format: { any: %w[match_a another_a] } })
      list_b = create(:subscriber_list, tags: { format: { any: %w[match_b another_b] } })
      create(:subscriber_list, tags: { format: { any: %w[another_a] } })
      create(:subscriber_list, tags: { format: { any: %w[another_b] } })

      result = described_class.call(
        SubscriberList,
        [
          {
            any_of: [
              {
                all_of: [
                  { type: "tag", key: "format", value: "match_a" },
                  { type: "tag", key: "format", value: "another_a" },
                ],
              },
              {
                all_of: [
                  { type: "tag", key: "format", value: "match_b" },
                  { type: "tag", key: "format", value: "another_b" },
                ],
              },
            ],
          },
        ],
      )

      expect(result).to contain_exactly(list_a, list_b)
    end

    it "can match a complicated nested scenario" do
      list = create(
        :subscriber_list,
        tags: { format: { any: %w[match_a match_c match_d match_e] } },
      )
      create(:subscriber_list)

      result = described_class.call(
        SubscriberList,
        [
          { type: "tag", key: "format", value: "match_a" },
          {
            any_of: [
              {
                all_of: [
                  {
                    any_of: [
                      { type: "tag", key: "format", value: "match_b" },
                      { type: "tag", key: "format", value: "not_match_b" },
                    ],
                  },
                  {
                    any_of: [
                      { type: "tag", key: "format", value: "match_c" },
                      { type: "tag", key: "format", value: "not_match_c" },
                    ],
                  },
                ],
              },
              {
                all_of: [
                  { type: "tag", key: "format", value: "match_d" },
                  { type: "tag", key: "format", value: "match_e" },
                ],
              },
            ],
          },
        ],
      )

      expect(result).to contain_exactly(list)
    end
  end
end
