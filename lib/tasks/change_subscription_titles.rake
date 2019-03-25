namespace :subscriber_list do
  desc "Update subscription titles to be more accurate and user friendly"
  task change_titles: :environment do
    puts "About to change titles"
    ActiveRecord::Base.transaction do
      translations = {
          "policy-papers-and-consultations-with-3-document-types-2" => "Policy papers",
          "policy-papers-and-consultations-with-4-document-types" => "Policy papers and open consultations",
          "policy-papers-and-consultations-with-6-document-types" => "Policy papers, open consultations and closed consultations",
          "policy-papers-and-consultations" => "Policy papers and consultations",
          "policy-papers-and-consultations-with-3-document-types" => "Open consultations and closed consultations",
          "policy-papers-and-consultations-with-2-document-types" => "Closed consultations",
          "policy-papers-and-consultations-with-5-document-types" => "Policy papers and closed consultations",
          "policy-papers-and-consultations-with-1-document-type" => "Open consultations"
      }

      translations.each_pair do |slug, new_title|
        subscriber_list = SubscriberList.find_by(slug: slug)
        if subscriber_list
          subscriber_list.update!(title: new_title)
        else
          raise ActiveRecord::Rollback, "Couldnt find #{slug}"
        end
      end
    end

    puts " All done now!"
  end
end
