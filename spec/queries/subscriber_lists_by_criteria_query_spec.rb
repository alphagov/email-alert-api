RSpec.describe SubscriberListsByCriteriaQuery do
  describe ".call" do
    it "can match a tag" do
      list = create(:subscriber_list, tags: { format: { any: %w[match] } })
      create(:subscriber_list, tags: { format: { any: %w[no-match] } })

      result = described_class.call(
        SubscriberList,
        [
          { type: "tag", key: "format", value: "match" }
        ]
      )

      expect(result).to match([list])
    end

    it "can match a link" do
      uuid = SecureRandom.uuid
      list = create(:subscriber_list, links: { format: { any: [uuid] } })
      create(:subscriber_list, links: { format: { any: [SecureRandom] } })

      result = described_class.call(
        SubscriberList,
        [
          { type: "link", key: "format", value: uuid }
        ]
      )

      expect(result).to match([list])
    end

    it "can match multiple tags" do
      list = create(:subscriber_list, tags: { format: { any: %w[match part_of_match] } })
      create(:subscriber_list, tags: { format: { any: %w[part_of_match] } })

      result = described_class.call(
        SubscriberList,
        [
          { type: "tag", key: "format", value: "match" },
          { type: "tag", key: "format", value: "part_of_match" }
        ]
      )

      expect(result).to match([list])
    end

    it "can match tags and links" do
      uuid = SecureRandom.uuid
      list = create(:subscriber_list,
                    tags: { format: { any: %w[match] } },
                    links: { format: { any: [uuid] } })
      create(:subscriber_list)

      result = described_class.call(
        SubscriberList,
        [
          { type: "tag", key: "format", value: "match" },
          { type: "link", key: "format", value: uuid }
        ]
      )

      expect(result).to match([list])
    end

    it "can match a tag with a double quote inside it" do
      unusual_tag = %{unusual string 'with things' that "might be escaped" like {} and []}
      list = create(:subscriber_list, tags: { format: { any: [unusual_tag] } })
      create(:subscriber_list)

      result = described_class.call(
        SubscriberList,
        [
          { type: "tag", key: "format", value: unusual_tag },
        ]
      )

      expect(result).to match([list])
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
              { type: "tag", key: "format", value: "match_b" }
            ]
          }
        ]
      )

      expect(result).to match([list_a, list_b])
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
                  { type: "tag", key: "format", value: "another_a" }
                ]
              },
              {
                all_of: [
                  { type: "tag", key: "format", value: "match_b" },
                  { type: "tag", key: "format", value: "another_b" }
                ],
              }
            ]
          }
        ]
      )

      expect(result).to match([list_a, list_b])
    end

    it "can match a complicated nested scenario" do
      list = create(
        :subscriber_list,
        tags: { format: { any: %w[match_a match_c match_d match_e] } }
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
                      { type: "tag", key: "format", value: "not_match_b" }
                    ]
                  },
                  {
                    any_of: [
                      { type: "tag", key: "format", value: "match_c" },
                      { type: "tag", key: "format", value: "not_match_c" }
                    ]
                  },
                ]
              },
              {
                all_of: [
                  { type: "tag", key: "format", value: "match_d" },
                  { type: "tag", key: "format", value: "match_e" }
                ],
              }
            ]
          }
        ]
      )

      expect(result).to match([list])
    end
  end
end
