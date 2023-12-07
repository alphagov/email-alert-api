RSpec.describe "Anonymising email addresses" do
  let(:sql) { File.read(RSpec.configuration.email_alert_api_sql_file_path) }

  let(:connection) { ActiveRecord::Base.connection }
  let(:column_names) do
    connection.tables.flat_map do |table|
      connection.columns(table).map { |column| "#{table}.#{column.name}" }
    end
  end

  def execute_sql
    connection.execute(sql)
  end

  it "deletes an email older than a day old" do
    create(:email, address: "foo@example.com", subject: "", body: "", created_at: Time.zone.parse("2023-12-05 12:34:56"))
    expect(Email.find_by(address: "foo@example.com")).not_to be_nil

    execute_sql

    expect(Email.find_by(address: "foo@example.com")).to be_nil
  end

  it "doesn't delete an email thats a day old or less" do
    create(:email, address: "foo@example.com", subject: "test", body: "", created_at: Time.now(in: "-02:00"))
    expect(Email.find_by(subject: "test")).not_to be_nil

    execute_sql

    expect(Email.find_by(subject: "test")).not_to be_nil
  end

  it "anonymises addresses in the subscribers table" do
    create(:subscriber, address: "foo@example.net")
    expect(Subscriber.find_by(address: "foo@example.net")).not_to be_nil

    execute_sql

    expect(Subscriber.find_by(address: "foo@example.net")).to be_nil
    expect(Subscriber.find_by(address: "anon-1@example.com")).not_to be_nil
  end

  it "keeps the pre-existing null addresses in the subscribers table" do
    create(:subscriber, address: "foo@example.com")
    create(:subscriber, :nullified)

    execute_sql

    expect(Subscriber.count).to eq(2)
    expect(Subscriber.all.map(&:address)).to include(nil)
  end

  it "anonymises addresses in the emails table" do
    create(:email, address: "foo@example.net")
    expect(Email.find_by(address: "foo@example.net")).not_to be_nil

    execute_sql

    expect(Email.find_by(address: "foo@example.net")).to be_nil
    expect(Email.find_by(address: "anon-1@example.com")).not_to be_nil
  end

  it "anonymises uses of addresses within the email" do
    email = create(
      :email,
      address: "foo@example.net",
      subject: "Email for foo@example.net",
      body: <<~BODY,
        [Thailand travel advice](https://www.gov.uk/foreign-travel-advice/thailand)

        10:51am, 4 April 2018: Another test that email sent ok

        ---
        You’re getting this email because you subscribed to ‘Thailand  - travel advice’ updates on GOV.UK.

        [Unsubscribe from ‘Thailand  - travel advice’](https://www.gov.uk/email/unsubscribe/8697f282-21f5-474f-a69f-abc3f70b18a8)
        [View, unsubscribe or change the frequency of your subscriptions](https://www.gov.uk/email/authenticate?address=foo@example.net)
      BODY
    )

    execute_sql
    email.reload

    expect(email.body).not_to match(/foo@example.net/)
    expect(email.subject).to eq("Email for anon-1@example.com")
    expect(email.body).to match(
      /#{Regexp.escape("[View, unsubscribe or change the frequency of your subscriptions](https://www.gov.uk/email/authenticate?address=anon-1@example.com)")}/,
    )
  end

  it "covers all cases where email/address appears in the database" do
    cases_covered = %w[subscribers.address emails.address users.email]
    other_columns = column_names - cases_covered

    cases_not_covered = other_columns.select do |name|
      name.end_with?("email", "address")
    end

    expect(cases_not_covered).to be_empty,
                                 "#{cases_not_covered.inspect} should have been anonymised"
  end

  it "assigns the same anonymous address if the original addresses were the same" do
    foo_subscriber_id = create(:subscriber, address: "foo@example.com").id
    bar_subscriber_id = create(:subscriber, address: "bar@example.com").id
    foo_email_id = create(:email, address: "foo@example.com").id
    bar_email_id = create(:email, address: "bar@example.com").id

    execute_sql
    foo_subscriber = Subscriber.find(foo_subscriber_id)
    bar_subscriber = Subscriber.find(bar_subscriber_id)
    foo_email = Email.find(foo_email_id)
    bar_email = Email.find(bar_email_id)

    expect(foo_email.address).to eq(foo_subscriber.address)
    expect(foo_email.address).to_not eq(bar_subscriber.address)
    expect(bar_email.address).to eq(bar_subscriber.address)
    expect(bar_subscriber.address).to_not eq(foo_subscriber.address)
  end

  it "handles addresses only differing in capitalisation" do
    create(:email, address: "foo@example.com")
    create(:email, address: "Foo@example.com")

    execute_sql
  end

  it "cleans up after itself" do
    expect { execute_sql }.not_to(change { connection.tables.count })
  end
end
