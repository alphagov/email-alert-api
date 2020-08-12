RSpec.describe Reports::BrexitSubscribersReport do
  describe "#call" do
    let(:tags) { { brexit_checklist_criteria: { any: %w[visiting-eu] } } }
    let(:list_1) { create(:subscriber_list, title: "brexit-1", slug: "/brexit-1", tags: tags) }
    let(:list_2) { create(:subscriber_list, title: "brexit-2", slug: "/brexit-2", tags: tags) }
    let(:date) { Time.zone.local(2020, 7, 12) }
    let(:before) { date - 1.day }
    let(:after) { date + 1.day }

    let(:subscriber_1) { create(:subscriber, created_at: before) }
    let!(:subscription_1) do
      create(:subscription, :daily,
             subscriber: subscriber_1,
             subscriber_list: list_1)
    end

    let(:subscriber_2) { create(:subscriber, created_at: after) }
    let!(:subscription_2) do
      create(:subscription, :daily,
             subscriber: subscriber_2,
             subscriber_list: list_2)
    end

    context "date is given" do
      it "returns an empty csv if there were no subscriptions created before the given date" do
        empty = <<~STR
          title,slug,tags,subscribed,unsubscribed,immediately,daily,weekly
        STR
        expect { described_class.call(date - 1.week) }.to output(empty).to_stdout
      end

      it "returns brexit lists subscribed to before the given date" do
        csv = <<~CSV
          title,slug,tags,subscribed,unsubscribed,immediately,daily,weekly
          brexit-1,/brexit-1,"{:brexit_checklist_criteria=>{:any=>[""visiting-eu""]}}",1,0,0,1,0
        CSV
        expect { described_class.call(date) }.to output(csv).to_stdout
      end
    end

    context "no date is given" do
      it "returns all brexit lists" do
        csv = <<~CSV
          title,slug,tags,subscribed,unsubscribed,immediately,daily,weekly
          brexit-1,/brexit-1,"{:brexit_checklist_criteria=>{:any=>[""visiting-eu""]}}",1,0,0,1,0
          brexit-2,/brexit-2,"{:brexit_checklist_criteria=>{:any=>[""visiting-eu""]}}",1,0,0,1,0
        CSV
        expect { described_class.call }.to output(csv).to_stdout
      end
    end
  end
end
