class PopulateAllSlugFields < ActiveRecord::Migration[5.1]
  def up
    @taken_slugs = SubscriberList.pluck(:slug)

    SubscriberList.find_each.with_index do |subscriber_list, i|
      puts "Slugified #{i} subscriber lists..." if (i % 1000).zero?

      slug = slugify(subscriber_list.title)
      subscriber_list.update(slug: slug)
      taken_slugs << slug
    end
  end

private

  attr_reader :taken_slugs

  def slugify(title)
    slug = title.parameterize
    index = 1

    while taken_slugs.include?(slug)
      index += 1
      slug = "#{title.parameterize}-#{index}"
    end

    slug
  end
end
