RSpec.describe GovDelivery::ResponseParser do
  let(:response_body) { nil }
  subject(:response_parser) { described_class.new(response_body) }

  context "with double keys" do
    let(:response_body) do
      %{
        <?xml version="1.0"?>
        <response>
          <error>test</error>
          <something_else>test</something_else>
          <error>test</error>
        </response>
      }
    end

    it "should only parse the first key" do
      expect(response_parser.parse.to_h).to eq(
        Struct
          .new(:error, :something_else)
          .new("test", "test")
          .to_h
      )
    end
  end
end
