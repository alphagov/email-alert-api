RSpec.describe CriteriaSchemaValidator do
  class CriteriaSchemaValidatable
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_accessor :criteria_rules
    validates :criteria_rules, criteria_schema: true
  end

  subject(:model) { CriteriaSchemaValidatable.new }

  context "Successful validation" do
    before do
      rules = [
        {
          type: "tag",
          key: "brexit_checklist_criteria",
          value: "eu-national"
        },
        {
          type: "tag",
          key: "brexit_checklist_criteria",
          value: "eu-resident"
        },
        {
          any_of: [
            {
              type: "tag",
              key: "brexit_checklist_criteria",
              value: "uk-resident"
            },
            {
              all_of: [
                {
                  type: "tag",
                  key: "brexit_checklist_criteria",
                  value: "ip"
                },
                {
                  type: "tag",
                  key: "brexit_checklist_criteria",
                  value: "exports"
                }
              ]
            }
          ]
        }
      ]

      model.criteria_rules = rules
    end

    it { is_expected.to be_valid }
  end

  context "Unsuccessful validation" do
    before do
      incorrectly_formatted_rules = [
        {
          type: "not-a-tag",
          key: "brexit_checklist_criteria",
          value: "eu-national"
        },
      ]

      model.criteria_rules = incorrectly_formatted_rules
    end

    it { is_expected.not_to be_valid }
  end

  context "Non json object" do
    before { model.criteria_rules = "" }

    it { is_expected.not_to be_valid }
  end
end
