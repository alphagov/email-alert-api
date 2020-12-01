module NotifyRequestHelpers
  def stub_notify
    body = {}.to_json
    stub_request(:post, /notifications\.service\.gov\.uk/).to_return(body: body)
  end

  def expect_an_email_was_sent
    request_data = nil
    expectation = ->(request) { request_data = JSON.parse(request.body).deep_symbolize_keys }
    expect(a_request(:post, /notifications\.service\.gov\.uk/).with(&expectation)).to have_been_made.at_least_once
    request_data
  end

  def expect_an_email_was_not_sent
    expect(a_request(:post, /notifications\.service\.gov\.uk/)).not_to have_been_made
  end

  def clear_any_requests_that_have_been_recorded!
    WebMock::RequestRegistry.instance.reset!
  end
end
