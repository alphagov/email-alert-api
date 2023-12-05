RSpec.describe "Anonymising email addresses" do
  let(:sql) { File.read(RSpec.configuration.email_alert_api_sql_file_path) }

  let(:connection) { ActiveRecord::Base.connection }
  let(:column_names) do
    connection.tables.flat_map do |table|
      connection.columns(table).map { |column| "#{table}.#{column.name}" }
    end
  end

  def execute_sql
    ActiveRecord::Base.connection.execute(sql.gsub(/#.*$/, ""))
  end

  it "deletes an email older than a day old" do
    email = create(:email, address: "foo@example.com", created_at: Time.zone.parse("13/03/2018 16:30:17"))
    execute_sql

    expect { email.reload }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it "doesn't delete an email thats a day old or less" do
    email = create(:email, address: "foo@example.com")
    execute_sql

    expect(email).to be_present
  end

  it "anonymises addresses in the subscribers table" do
    subscriber = create(:subscriber, address: "foo@example.com")

    expect { execute_sql }
      .to change { subscriber.reload.address }
      .to("anonymous-1@example.com")
  end

  it "keeps the pre-existing null addresses in the subscribers table" do
    create(:subscriber, address: "foo@example.com")
    create(:subscriber, :nullified)

    execute_sql

    expect(Subscriber.count).to eq(2)
    expect(Subscriber.all.map(&:address)).to include(nil)
  end

  it "anonymises addresses in the emails table" do
    email = create(:email, address: "foo@example.com")

    expect { execute_sql }
      .to change { email.reload.address }
      .to("anonymous-1@example.com")
  end

  it "does not anonymise signon user addresses" do
    user = create(:user, email: "foo@digital.cabinet-office.gov.uk")
    expect { execute_sql }.not_to(change { user.reload.email })
  end

  it "anonymises uses of addresses within the email" do
    email = create(
      :email,
      address: "foo@example.com",
      subject: "Email for foo@example.com",
      body: <<~HDOC,
        [Thailand travel advice](https://www.gov.uk/foreign-travel-advice/thailand)

        10:51am, 4 April 2018: Another test that email sent ok

        ---
        You’re getting this email because you subscribed to ‘Thailand  - travel advice’ updates on GOV.UK.

        [Unsubscribe from ‘Thailand  - travel advice’](https://www.gov.uk/email/unsubscribe/8697f282-21f5-474f-a69f-abc3f70b18a8)
        [View, unsubscribe or change the frequency of your subscriptions](https://www.gov.uk/email/authenticate?address=foo@example.com)
      HDOC
    )

    execute_sql
    email.reload
    expect(email.body).not_to match(/foo@example.com/)
    expect(email.subject).to eq("Email for anonymous-1@example.com")
    expect(email.body).to match(
      /#{Regexp.escape("[View, unsubscribe or change the frequency of your subscriptions](https://www.gov.uk/email/authenticate?address=anonymous-1@example.com)")}/,
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
    foo_subscriber = create(:subscriber, address: "foo@example.com")
    bar_subscriber = create(:subscriber, address: "bar@example.com")

    foo_email = create(:email, address: "foo@example.com")
    bar_email = create(:email, address: "bar@example.com")

    execute_sql

    expect(foo_email.reload.address).to eq(foo_subscriber.reload.address)
    expect(foo_email.reload.address).to_not eq(bar_subscriber.reload.address)

    expect(bar_email.reload.address).to eq(bar_subscriber.reload.address)
    expect(bar_subscriber.reload.address).to_not eq(foo_subscriber.reload.address)
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
