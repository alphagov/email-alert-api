RSpec.describe "Anonymising email addresses" do
  let(:sql) { File.read("lib/data_hygiene/anonymise_email_addresses.sql") }

  let(:connection) { ActiveRecord::Base.connection }
  let(:columns) { connection.tables.flat_map { |t| connection.columns(t) } }
  let(:column_names) { columns.map { |c| "#{c.table_name}.#{c.name}" } }

  def execute_sql
    ActiveRecord::Base.connection.execute(sql)
  end

  it "anonymises addresses in the subscribers table" do
    subscriber = create(:subscriber, address: "foo@example.com")

    expect { execute_sql }
      .to change { subscriber.reload.address }
      .to("anonymous-1@example.com")
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

  it "covers all cases where email/address appears in the database" do
    cases_covered = %w(subscribers.address emails.address users.email)
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

    expect(foo_subscriber.reload.address).to eq("anonymous-1@example.com")
    expect(bar_subscriber.reload.address).to eq("anonymous-2@example.com")

    expect(foo_email.reload.address).to eq("anonymous-1@example.com")
    expect(bar_email.reload.address).to eq("anonymous-2@example.com")
  end

  it "cleans up after itself" do
    expect { execute_sql }.not_to(change { connection.tables.count })
  end
end
