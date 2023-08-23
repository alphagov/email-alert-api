require "sidekiq/api"
require "sitemap-parser"

namespace :subscriber_list_audit do
  desc "Create audit workers"
  task :start, %i[batch_size] => :environment do |_t, args|
    batch_size = args.fetch(:batch_size, "100").to_i

    puts("Creating audit workers with batch size #{batch_size}")

    base_sitemap = SitemapParser.new("#{Plek.website_root}/sitemap.xml")
    sitemap_parts = base_sitemap.sitemap.at("sitemapindex").element_children.map { |element| element.at("loc").content }

    audit_start_time = Time.zone.now

    sitemap_parts.each do |sitemap_url|
      sitemap = SitemapParser.new(sitemap_url)
      urls = sitemap.to_a

      puts("Read #{urls.count} URLs from sitemap section #{sitemap_url}")

      urls.each_slice(batch_size) do |batch|
        SubscriberListAuditWorker.perform_async(batch, audit_start_time.to_s)
      end
    end

    puts("Batch workers created. Use rails subscriber_list_audit:queue_size to monitor queue size")
  end

  desc "Check audit worker queue size"
  task queue_size: :environment do
    audit_queue = Sidekiq::Queue.new(:subscriber_list_audit)
    puts("#{audit_queue.size} jobs remaining to be processed")
  end

  desc "Show Subscriber Lists unaudited since a given date (defaults to now)"
  task :report, %i[since_date] => :environment do |_t, args|
    since_date = Date.parse(args.fetch(:since_date, Time.zone.now.to_s))
    SubscriberList.unaudited_since(since_date).each do |subscriber_list|
      puts("#{subscriber_list.id}: #{subscriber_list.title}")
    end
  end
end
