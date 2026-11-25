COUNTRY_LIST = {
  "Nauru" => "Naoero",
  "St Eustatius" => "Sint Eustatius",
  "St Maarten" => "Sint Maarten",
  "Bahamas" => "The Bahamas",
}.freeze

desc "Find subscriber lists by title match"
task country_name_change_find_lists: :environment do
  COUNTRY_LIST.each do |original, new|
    subscriber_lists = SubscriberList.where("title ILIKE ?", "%#{original}%")

    puts "============================="
    puts "#{original}: #{subscriber_lists.count} lists"
    puts "============================="
    if subscriber_lists.present?
      subscriber_lists.each do |subscriber_list|
        new_title = subscriber_list.title.gsub(original, new)
        new_slug = subscriber_list.slug.gsub(original.downcase.parameterize, new.downcase.parameterize)

        puts "title: #{subscriber_list.title} -> #{new_title}"
        puts "slug: #{subscriber_list.slug} -> #{new_slug}"

        subscriber_list.title = new_title
        subscriber_list.slug = new_slug
        subscriber_list.save!
      end
    end
    puts ""
  end
end
