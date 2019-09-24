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
          "policy-papers-and-consultations-with-1-document-type" => "Open consultations",
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

  desc "Update business readiness titles containing `EU Exit` to `Brexit`"
  task change_business_readiness_titles: :environment do
    title = "EU Exit guidance for your business"

    subscriber_lists = SubscriberList.where("title ILIKE ?", "%#{title}%")

    raise "Cannot find any subscriber lists with title containing `#{title}`" if subscriber_lists.nil?

    puts "============================="

    puts "Found #{subscriber_lists.count} subscriber lists containing '#{title}'"

    subscriber_lists.each do |subscriber_list|
      puts "============================="
      puts "Original title: '#{subscriber_list.title}'"
      puts "Original slug: '#{subscriber_list.slug}'"

      new_title = subscriber_list.title.gsub("EU Exit guidance", "Brexit guidance")
      new_slug = subscriber_list.slug.gsub("eu-exit-guidance", "brexit-guidance")

      subscriber_list.title = new_title
      subscriber_list.slug = new_slug

      if subscriber_list.save!
        puts "Subscriber list updated with title: '#{new_title}' and slug: '#{new_slug}'"
      else
        puts "Error updating subscriber list with title: '#{new_title}' and slug: '#{new_slug}'"
      end
    end
  end
end
