RSpec.describe "temp_fix_world_subs" do
  # Content ID comes from world_taxons.csv file
  let(:dead_2a_type_links) { { world_locations: { any: %w[2b479119-7612-4a76-a695-c429c98c89a0] } } }
  let(:alive_2_type_links) { { taxon_tree: { any: %w[2b479119-7612-4a76-a695-c429c98c89a0] } } }
  let(:dead_4_type_links) { { world_locations: { any: %w[7463bc01-8b53-448a-af7a-401e01388a61] } } }

  before do
    Rake::Task["temp_fix_world_subs"].reenable
  end

  it "reports unambiguous lists it can auto-fix" do
    dead_2a_type_list = create :subscriber_list, title: "Living in Spain", slug: "living-in-spain-2", links: dead_2a_type_links
    create :subscriber_list, title: "Living in Spain", slug: "living-in-spain", links: alive_2_type_links

    create :subscription, subscriber_list: dead_2a_type_list
    create :subscription, :ended, subscriber_list: dead_2a_type_list

    expect { Rake::Task["temp_fix_world_subs"].invoke }
      .to output("Living in Spain (living-in-spain-2, 1 subscriptions) - fixable, merging into 'living-in-spain'\n")
      .to_stdout
  end

  it "reports corrupted lists it will delete" do
    dead_4_type_list = create :subscriber_list, title: "Spain", slug: "uk-help-and-services-in-spain", links: dead_4_type_links

    create :subscription, subscriber_list: dead_4_type_list
    create :subscription, :ended, subscriber_list: dead_4_type_list

    expect { Rake::Task["temp_fix_world_subs"].invoke }
      .to output("Spain (uk-help-and-services-in-spain, 1 subscriptions) - permanently corrupted, deleting\n")
      .to_stdout
  end

  it "ignores lists that were never broken" do
    expect { Rake::Task["temp_fix_world_subs"].invoke }.to_not output.to_stdout
  end

  it "creates missing lists that are working" do
    create :subscriber_list, title: "Living in Spain", slug: "living-in-spain-2", links: dead_2a_type_links
    expect { Rake::Task["temp_fix_world_subs"].invoke(true) }.to output.to_stdout

    alive_2_type_list = SubscriberList.find_by(links_digest: HashDigest.new(alive_2_type_links).generate)
    expect(alive_2_type_list).to be
  end

  it "unsubscribes everyone from corrupted lists" do
    dead_4_type_list = create :subscriber_list, title: "Spain", slug: "uk-help-and-services-in-spain", links: dead_4_type_links
    subscription = create :subscription, subscriber_list: dead_4_type_list

    expect { Rake::Task["temp_fix_world_subs"].invoke(true) }.to output.to_stdout

    expect(Subscription.active.count).to be_zero
    expect(subscription.reload.ended_reason).to eq "subscriber_list_changed"
  end

  it "moves fixable subscriptions to the right list" do
    dead_2a_type_list = create :subscriber_list, title: "Living in Spain", slug: "living-in-spain-2", links: dead_2a_type_links
    alive_2_type_list = create :subscriber_list, title: "Living in Spain", slug: "living-in-spain", links: alive_2_type_links

    dead_active_subscription = create :subscription, subscriber_list: dead_2a_type_list
    create :subscription, :ended, subscriber_list: dead_2a_type_list

    expect { Rake::Task["temp_fix_world_subs"].invoke(true) }.to output.to_stdout
    new_subscriptions = alive_2_type_list.subscriptions

    expect(new_subscriptions.count).to eq 1
    expect(new_subscriptions.first.subscriber).to eq dead_active_subscription.subscriber
    expect(dead_2a_type_list.subscriptions.active.count).to be_zero
  end

  it "changes nothing unless the 'for_reals' flag is set" do
    dead_4_type_list = create :subscriber_list, title: "Spain", slug: "uk-help-and-services-in-spain", links: dead_4_type_links
    dead_2a_type_list = create :subscriber_list, title: "Living in Spain", slug: "living-in-spain-2", links: dead_2a_type_links

    create :subscription, subscriber_list: dead_4_type_list
    create :subscription, subscriber_list: dead_2a_type_list

    expect { Rake::Task["temp_fix_world_subs"].invoke }
      .to output.to_stdout
      .and change { Subscription.count }.by(0)
      .and change { SubscriberList.count }.by(0)
  end
end
