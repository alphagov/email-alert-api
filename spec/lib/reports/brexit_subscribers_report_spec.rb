RSpec.describe Reports::BrexitSubscribersReport do
  describe "#call" do
    let!(:date) { Time.zone.local(2020, 7, 12) }
    let(:list) { create(:subscriber_list, :brexit, title: "brexit", slug: "/brexit") }
    let(:subscriber) { create(:subscriber) }
    let!(:subscription) do
      create(:subscription, :daily,
             subscriber: subscriber,
             subscriber_list: list,
             created_at: (date + 1.day))
    end

    context "date is given" do
      it "returns all brexit lists subscribed to before a date" do
        empty = <<~STR
          title,slug,tags,subscribed,unsubscribed,immediately,daily,weekly
        STR
        expect { described_class.new(date).call }.to output(empty).to_stdout
      end
    end

    context "no date is given" do
      it "returns all brexit lists" do
        csv = <<~CSV
          title,slug,tags,subscribed,unsubscribed,immediately,daily,weekly
          brexit,/brexit,"{:brexit_checklist_criteria=>{:any=>[""visiting-eu""]}}",1,0,0,1,0
        CSV
        expect { described_class.new.call }.to output(csv).to_stdout
      end
    end
  end
end
