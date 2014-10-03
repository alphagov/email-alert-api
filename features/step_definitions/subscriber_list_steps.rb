Given(/^there are no subscriber lists$/) do
  # TODO: This may need to be more than a noop at some point
end

Given(/^the subscriber list does not already exist$/) do
end

Then(/^a subscriber list is created$/) do
  expect(GOV_DELIVERY_API_CLIENT.created_topics.values).to include(
    name: "CMA cases of type Markets and Mergers and about Energy",
  )

  # %{
  #   <topic>
  #     <name>CMA cases of type Markets and Mergers and about Energy</name>
  #     <visibility>Unlisted</visibility>
  #     <pagewatch-enabled type="boolean">false</pagewatch-enabled>
  #     <rss-feed-url nil="true"></rss-feed-url>
  #     <rss-feed-title nil="true"></rss-feed-title>
  #     <rss-feed-description nil="true"></rss-feed-description>
  #   </topic>
  # }
end

Given(/^a subscriber list already exists$/) do
  @tag_set = {
    "document_type" => [ "cma_case" ],
    "case_type" => [ "markets", "mergers" ],
    "market_sector" => [ "energy" ],
  }

  params = {
    "title" => "CMA cases of type Markets and Mergers and about Energy",
    "tags" => @tag_set,
  }

  create_subscriber_list(params)
end

When(/^I POST to "(.*?)" with duplicate tag set$/) do |path|
  params = {
    "title" => "Any title",
    "tags" => @tag_set,
  }

  @response = post(path, params)
end

When(/^I POST to "(.*?)" with duplicate but differently ordered tag set$/) do |path|
  duplicate_tags_with_different_order = @tag_set
    .reduce({}) { |result, (tag, values)|
      result.merge(tag => values.reverse)
    }

  params = {
    "title" => "Any title",
    "tags" => duplicate_tags_with_different_order,
  }

  @response = post(path, params)
end

When(/^When I POST to "(.*?)" with invalid parameters$/) do |path|
  params = {
    "not_title" => "Any title",
    "tags" => ["not", "a", "hash"],
  }

  @response = post(path, params)
end

Then(/^a subscriber list has not been created$/) do
  expect(GOV_DELIVERY_API_CLIENT.created_topics.size).to eq(1)
end

Given(/^the subscriber list "(.*?)" with tags$/) do |name, tags|
  tags = JSON.load(tags)

  @subscriber_list = create_subscriber_list(
    "title" => name,
    "tags" => tags,
  ).fetch(:subscriber_list)
end

Then(/^a notification is sent to the subscriber list$/) do
  expect(GOV_DELIVERY_API_CLIENT.notifications.map(&:to_h)).to include(
    topic_id: @subscriber_list.gov_delivery_id,
    subject: @request_body.fetch("subject"),
    body: @request_body.fetch("body"),
  )
end
