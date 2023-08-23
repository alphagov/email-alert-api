require "sidekiq/api"
require "sitemap-parser"

namespace :subscriber_list_audit do
  desc "Create audit workers"
  task :start, %i[batch_size limit] => :environment do |_t, args|
    batch_size = (args[:batch_size] || "10").to_i
    limit = args[:limit] ? args[:limit].to_i : -1

    abort("SubscriberListAudit not empty") if SubscriberListAudit.any?

    puts("Creating audit workers with batch size #{batch_size}, limit #{limit}")

    sitemaps = limit == -1 ? 29 : 1

    (1..sitemaps).each do |i|
      sitemap = SitemapParser.new("#{Plek.website_root}/sitemaps/sitemap_#{i}.xml")
      urls = sitemap.to_a

      urls = urls.take(limit) if limit != -1

      puts("Read #{urls.count} URLs from sitemap part #{i}")

      urls.each_slice(batch_size) do |batch|
        SubscriberListAuditWorker.perform_async(batch)
      end
    end

    puts("Batch workers created. Use rails subscriber_list_audit:queue_size to monitor queue size")
  end

  desc "Check audit worker queue size"
  task queue_size: :environment do
    audit_queue = Sidekiq::Queue.new(:subscriber_list_audit)
    puts("#{audit_queue.size} jobs remaining to be processed")
  end

  desc "Show Subscriber Lists that cannot be triggered"
  task report: :environment do
    SubscriberList.all do |subscriber_list|
      puts("#{subscriber_list.id}: #{subscriber_list.title}") unless SubscriberListAudit.where(subscriber_list:).any?
    end
  end
end
