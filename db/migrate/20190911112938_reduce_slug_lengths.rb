class ReduceSlugLengths < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    SubscriberList.where("LENGTH(slug) > 255").find_each do |list|
      list.update!(slug: slugify(list.title))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def slugify(title)
    slug = title.parameterize.truncate(255, omission: '', separator: '-')

    while SubscriberList.where(slug: slug).exists?
      slug = title.parameterize.truncate(244, omission: '', separator: '-')
      slug += "-#{SecureRandom.hex(5)}"
    end

    slug
  end
end
