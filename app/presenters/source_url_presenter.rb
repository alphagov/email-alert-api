class SourceUrlPresenter < ApplicationPresenter
  def initialize(url)
    @url = url
  end

  def call
    url_for_brexit_checker_results if url =~ %r{transition-check/results}
  end

private

  attr_reader :url

  def url_for_brexit_checker_results
    absolute_url = PublicUrls.url_for(base_path: url)
    "[You can view a copy of your results on GOV.UK](#{absolute_url})"
  end
end
