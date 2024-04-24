SITEMAP_INDEX = <<-SITEMAP_INDEX_XML.freeze
  <?xml version='1.0' encoding='UTF-8'?>
  <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <sitemap>
      <loc>http://www.dev.gov.uk/sitemaps/sitemap_1.xml</loc>
      <lastmod>2024-04-22T02:50:02+00:00</lastmod>
    </sitemap>
  </sitemapindex>
SITEMAP_INDEX_XML

SITEMAP = <<-SITEMAP_XML.freeze
  <?xml version='1.0' encoding='UTF-8'?>
  <urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
      xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <url>
          <loc>http://www.dev.gov.uk/example-page-1</loc>
          <lastmod>2006-11-18</lastmod>
          <changefreq>daily</changefreq>
          <priority>0.8</priority>
      </url>
  </urlset>
SITEMAP_XML

RSpec.describe "subscriber_list_audit" do
  describe "start" do
    before do
      stub_request(:get, "http://www.dev.gov.uk/sitemap.xml").to_return(status: 200, body: SITEMAP_INDEX, headers: {})
      stub_request(:get, "http://www.dev.gov.uk/sitemaps/sitemap_1.xml").to_return(status: 200, body: SITEMAP, headers: {})
    end

    it "outputs a CSV of matched content changes" do
      expected_string = <<~END_EXPECTED_STRING
        Creating audit workers with batch size 100
        Read 1 URLs from sitemap section http://www.dev.gov.uk/sitemaps/sitemap_1.xml
        Batch workers created. Use rails subscriber_list_audit:queue_size to monitor queue size
      END_EXPECTED_STRING

      expect { Rake::Task["subscriber_list_audit:start"].invoke }
        .to output(expected_string).to_stdout
    end
  end

  describe "queue_size" do
    it "outputs a CSV of matched content changes" do
      expect { Rake::Task["subscriber_list_audit:queue_size"].invoke }
        .to output("0 jobs remaining to be processed\n").to_stdout
    end
  end

  describe "report" do
    before do
      @sl = create(:subscriber_list)
    end

    it "outputs a CSV of matched content changes" do
      expect { Rake::Task["subscriber_list_audit:report"].invoke }
        .to output("#{@sl.id}: #{@sl.title}\n").to_stdout
    end
  end
end
