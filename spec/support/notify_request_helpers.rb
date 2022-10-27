module NotifyRequestHelpers
  def stub_notify
    body = {}.to_json
    stub_request(:post, /notifications\.service\.gov\.uk/).to_return(body:)
  end

  def expect_an_email_was_sent(subject: /.*/, address: "test@test.com")
    request_data = nil

    expectation = lambda do |request|
      request_data = JSON.parse(request.body).deep_symbolize_keys

      request_data[:email_address] == address &&
        request_data.dig(:personalisation, :subject).match?(subject)
    end

    expect(a_request(:post, /notifications\.service\.gov\.uk/)
      .with(&expectation)).to have_been_made.at_least_once

    request_data
  end

  def expect_an_email_was_not_sent
    expect(a_request(:post, /notifications\.service\.gov\.uk/)).not_to have_been_made
  end

  def clear_any_requests_that_have_been_recorded!
    WebMock::RequestRegistry.instance.reset!
  end
end
