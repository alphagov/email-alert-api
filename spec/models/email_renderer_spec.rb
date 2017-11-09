require 'rails_helper'

RSpec.describe EmailRenderer do
  let(:params) do
    {
      title: "Title",
      public_updated_at: DateTime.parse("1/1/2017"),
      description: "Description",
      change_note: "Change note",
    }
  end

  let(:renderer) { EmailRenderer.new(params: params) }

  describe "subject" do
    it "should match the title" do
      expect(renderer.subject).to eq(params[:title])
    end
  end

  describe "body" do
    it "should match the expected content" do
      expect(renderer.body).to eq(
        <<~BODY
          There has been a change to *Title* on 00:00 1 January 2017.

          > Description

          **Change note**
        BODY
      )
    end
  end
end
