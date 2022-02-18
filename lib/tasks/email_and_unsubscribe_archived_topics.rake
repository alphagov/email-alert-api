namespace :archived_topics do
  desc "Send a bulk email to subscribers to these archived Specialist Topics."
  task :send_emails, [] => :environment do |_t, _args|
    topic_urls.each do |topic|
      sub_list = SubscriberList.find_by(url: topic[:url])
      if !sub_list
        puts "No SubscriberList for #{topic[:url]}"
      else
        puts "Sending email for #{sub_list.url} (ID: #{sub_list.id})"

        body = <<~BODY
          Update from GOV.UK for:

          #{sub_list.title}

          _________________________________________________________________

          You asked GOV.UK to email you when we add or update a page about:


          #{sub_list.title}

          This topic has been archived. You will not get any more emails about it.

          You can find more information about this topic at [#{topic[:redirect_title]}](#{topic[:redirect_url]}).
          You can find more information about this topic at [#{topic[:redirect_title]}](#{topic[:redirect]}).
        BODY

        email_ids = BulkSubscriberListEmailBuilder.call(
          subject: "Update from GOV.UK for: #{sub_list.title}",
          body: body,
          subscriber_lists: [sub_list],
        )

        email_ids.each do |id|
          SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
        end

        puts "Destroying subscription list #{sub_list.url} (ID: #{sub_list.id})"
        sub_list.destroy!
      end
    end
  end
end

def topic_urls
  [
    {
      "url": "/topic/benefits-credits/universal-credit",
      "redirect": "/universal-credit",
      "redirect_title": "Universal Credit",
    },
    {
      "url": "/topic/climate-change-energy/international-climate-change",
      "redirect": "/guidance/international-climate-finance",
      "redirect_title": "International Climate Finance",
    },
    {
      "url": "/topic/coal/environment",
      "redirect": "/browse/business/waste-environment",
      "redirect_title": "Waste and environmental impact",
    },
    {
      "url": "/topic/coal/water-management",
      "redirect": "/government/collections/coal-mine-water-treatment",
      "redirect_title": "Coal mine water treatment",
    },
    {
      "url": "/topic/commercial-fishing-fisheries/vessel-surveys-inspections",
      "redirect": "/government/collections/safety-of-fishing-vessels-and-crew",
      "redirect_title": "Safety of fishing vessels and crew",
    },
    {
      "url": "/topic/farming-food-grants-payments/intervention-schemes",
      "redirect": "/guidance/intervention-and-private-storage-aid-schemes",
      "redirect_title": "Intervention and Private Storage Aid schemes",
    },
    {
      "url": "/topic/farming-food-grants-payments/private-storage-aid",
      "redirect": "/guidance/intervention-and-private-storage-aid-schemes",
      "redirect_title": "Intervention and Private Storage Aid schemes",
    },
    {
      "url": "/topic/farming-food-grants-payments/school-milk-scheme",
      "redirect": "/government/collections/the-school-milk-subsidy-scheme-guidance",
      "redirect_title": "School Milk Subsidy Scheme",
    },
    {
      "url": "/topic/higher-education/scholarships-for-overseas-students",
      "redirect": "/browse/education/student-finance",
      "redirect_title": "Student finance",
    },
    {
      "url": "/topic/housing/design-and-sustainability",
      "redirect": "/browse/housing-local-services/planning-permission",
      "redirect_title": "Planning permission and building regulations",
    },
    {
      "url": "/topic/immigration-operational-guidance/commerical-casework-guidance",
      "redirect": "/government/publications/representatives-of-overseas-businesses",
      "redirect_title": "Representatives of overseas businesses caseworker guidance",
    },
    {
      "url": "/topic/immigration-operational-guidance/non-compliance-biometric-registration",
      "redirect": "/government/publications/non-compliance-with-the-biometric-registration-regulations",
      "redirect_title": "Non-compliance with the biometric registration regulations",
    },
    {
      "url": "/topic/immigration-operational-guidance/rights-responsibilities",
      "redirect": "/government/publications/asylum-applicants-rights-and-responsibilities",
      "redirect_title": "Asylum applicants' rights and responsibilities",
    },
    {
      "url": "/topic/immigration-operational-guidance/stateless-guidance",
      "redirect": "/government/publications/stateless-guidance",
      "redirect_title": "Stateless guidance",
    },
    {
      "url": "/topic/law-justice-system/statutory-rights",
      "redirect": "/browse/justice/courts-sentencing-tribunals",
      "redirect_title": "Courts, sentencing and tribunals",
    },
    {
      "url": "/topic/local-government/councils-elections",
      "redirect": "/guidance/local-government-structure-and-elections",
      "redirect_title": "Local government structure and elections",
    },
    {
      "url": "/topic/local-government/data-collection-reporting",
      "redirect": "/government/publications/single-data-list",
      "redirect_title": "Single data list",
    },
    {
      "url": "/topic/medicines-medical-devices-blood/payment-and-fees",
      "redirect": "/government/publications/mhra-fees",
      "redirect_title": "MHRA fees",
    },
    {
      "url": "/topic/mot/provide-mot-training",
      "redirect": "/guidance/become-an-mot-training-provider",
      "redirect_title": "Provide MOT training courses",
    },
    {
      "url": "/topic/oil-and-gas/carbon-capture-and-storage",
      "redirect": "/guidance/uk-carbon-capture-and-storage-government-funding-and-support",
      "redirect_title": "UK carbon capture, usage and storage",
    },
    {
      "url": "/topic/oil-and-gas/exploration-and-production",
      "redirect": "/guidance/onshore-oil-and-gas-sector-guidance",
      "redirect_title": "Onshore oil and gas sector guidance",
    },
    {
      "url": "/topic/oil-and-gas/fields-and-wells",
      "redirect": "/guidance/onshore-oil-and-gas-sector-guidance",
      "redirect_title": "Onshore oil and gas sector guidance",
    },
    {
      "url": "/topic/oil-and-gas/infrastructure-and-decommissioning",
      "redirect": "/guidance/oil-and-gas-decommissioning-of-offshore-installations-and-pipelines",
      "redirect_title": "Oil and gas: decommissioning of offshore installations and pipelines",
    },
    {
      "url": "/topic/oil-and-gas/onshore-oil-and-gas (3 tagged items)",
      "redirect": "/guidance/onshore-oil-and-gas-sector-guidance",
      "redirect_title": "Onshore oil and gas sector guidance",
    },
    {
      "url": "/topic/prisons-probation/information-suppliers",
      "redirect": "/government/organisations/ministry-of-justice/about/procurement",
      "redirect_title": "Procurement at MOJ",
    },
    {
      "url": "/topic/prisons-probation/mappa",
      "redirect": "/government/publications/multi-agency-public-protection-arrangements-mappa-guidance",
      "redirect_title": "Multi-agency public protection arrangements (MAPPA): Guidance",
    },
    {
      "url": "/topic/prisons-probation/operational-guidance",
      "redirect": "/guidance/prison-service-orders-psos",
      "redirect_title": "Prison service orders (PSOs)",
    },
    {
      "url": "/topic/ships-cargoes/emergency-life-saving-equipment",
      "redirect": "/emergency-and-lifesaving-equipment-on-ships",
      "redirect_title": "Emergency and life-saving equipment on ships",
    },
    {
      "url": "/topic/ships-cargoes/high-speed-craft",
      "redirect": "/guidance/high-speed-craft-construction-and-maintenance-standards",
      "redirect_title": "High-speed craft: construction and maintenance standards",
    },
    {
      "url": "/topic/ships-cargoes/requirements-for-reporting-vessels",
      "redirect": "/guidance/how-to-provide-mandatory-vessel-reporting-information-to-the-mca",
      "redirect_title": "How to provide mandatory vessel reporting information to the MCA",
    },
    {
      "url": "/topic/transport/environment",
      "redirect": "/browse/driving/parking-public-transport-environment",
      "redirect_title": "Parking, public transport and the environment",
    },
    {
      "url": "/topic/work-careers/trade-unions",
      "redirect": "/browse/employing-people/trade-unions",
      "redirect_title": "Trade unions and workers rights",
    },
  ]
end
