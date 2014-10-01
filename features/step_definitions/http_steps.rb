When(/^I POST to "(.*?)" with$/) do |path, request_body_json|
  @request_body = JSON.load(request_body_json)
  @response = post(path, @request_body)
end

Then(/^I get a "(.*?)" response with the following body$/) do |status, expected_response_body_json|
  expect(@response.status).to eq(status.to_i)

  response_data = JSON.load(@response.body)
  expected_response_data = JSON.load(expected_response_body_json)

  # all responses that are asserted on thus far are attr hashes in nested under
  # a single key. Comparing the nested values first gives a more readable diff.
  expect(response_data.values.first).to eq(expected_response_data.values.first)

  expect(response_data).to eq(expected_response_data)
end
