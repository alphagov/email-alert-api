When(/^I POST to "(.*?)" with$/) do |path, request_body_json|
  @response = post(path, JSON.load(request_body_json))
end

Then(/^I get the response$/) do |expected_response_body_json|
  expect(JSON.load(@response.body))
    .to eq(JSON.load(expected_response_body_json))
end
