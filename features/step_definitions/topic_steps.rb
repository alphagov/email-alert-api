Given(/^there are no topics$/) do
  # TODO: This may need to be more than a noop at some point
end

Then(/^a topic is created$/) do
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

Given(/^a topic already exists$/) do
  @tag_set = {
    "document_type" => [ "cma_case" ],
    "case_type" => [ "markets", "mergers" ],
    "market_sector" => [ "energy" ],
  }

  params = {
    "title" => "CMA cases of type Markets and Mergers and about Energy",
    "tags" => @tag_set,
  }

  create_topic(params)
end

When(/^I POST to "(.*?)" with duplicate tag set$/) do |path|
  params = {
    "title" => "Any title",
    "tags" => @tag_set,
  }

  @response = post(path, params)
end

Then(/^a topic has not been created$/) do
  expect(GOV_DELIVERY_API_CLIENT.created_topics.size).to eq(1)
end

Given(/^the topic "(.*?)" with tags$/) do |name, tags|
  tags = JSON.load(tags)

  @topic = create_topic(
    "title" => name,
    "tags" => tags,
  ).fetch(:topic)
end

Then(/^a notification is sent to the topic$/) do
  expect(GOV_DELIVERY_API_CLIENT.notifications.map(&:to_h)).to include(
    topic_id: @topic.gov_delivery_id,
    subject: @request_body.fetch("subject"),
    body: @request_body.fetch("body"),
  )
end
