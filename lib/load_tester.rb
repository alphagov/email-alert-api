class LoadTester
  def self.test_delivery_request_workers(number)
    new.test_delivery_request_workers(number)
  end

  def test_delivery_request_workers(number)
    email = create_test_email(to: success_address(0))

    number.times do
      DeliveryRequestWorker.perform_async(email.id)
    end
  end

private

  def create_test_email(to:)
    Email.create!(
      address: to,
      subject: "Subject",
      body: "Body",
    )
  end

  def success_address(n)
    tag = n.to_s.rjust(8, "0")
    "success+#{tag}@simulator.amazonses.com"
  end
end
