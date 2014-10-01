When(/^I POST to "(.*?)" with$/) do |path, request_body_json|
  @request_body = JSON.load(request_body_json)
  @response = post(path, @request_body)
end

Then(/^I get a "(.*?)" response with the following body$/) do |status, expected_response_body_json|
  expect(@response.status).to eq(status.to_i)
  expect(JSON.load(@response.body))
    .to eq(JSON.load(expected_response_body_json))
end
