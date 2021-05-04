RSpec.describe CriteriaSchemaValidator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      include ActiveModel::Model

      attr_accessor :criteria_rules

      validates :criteria_rules, criteria_schema: true
    end
  end

  it "is valid for a format that meets the schema" do
    rules = [
      {
        type: "tag",
        key: "brexit_checklist_criteria",
        value: "eu-national",
      },
      {
        type: "tag",
        key: "brexit_checklist_criteria",
        value: "eu-resident",
      },
      {
        any_of: [
          {
            type: "tag",
            key: "brexit_checklist_criteria",
            value: "uk-resident",
          },
          {
            all_of: [
              {
                type: "tag",
                key: "brexit_checklist_criteria",
                value: "ip",
              },
              {
                type: "tag",
                key: "brexit_checklist_criteria",
                value: "exports",
              },
            ],
          },
        ],
      },
    ]

    expect(record_class.new(criteria_rules: rules)).to be_valid
  end

  it "is invalid for rules that don't match the schema" do
    rules = [
      {
        type: "not-a-tag",
        key: "brexit_checklist_criteria",
        value: "eu-national",
      },
    ]

    expect(record_class.new(criteria_rules: rules)).to be_invalid
  end

  it "is invalid when input is not an array" do
    expect(record_class.new(criteria_rules: "")).to be_invalid
  end
end
