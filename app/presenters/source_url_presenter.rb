class SourceUrlPresenter < ApplicationPresenter
  def initialize(url)
    @url = url
  end

  def call
    url_for_brexit_checker_results if is_a_brexit_checker_list?
  end

private

  attr_reader :url

  def url_for_brexit_checker_results
    absolute_url = PublicUrls.url_for(base_path: url)
    "[You can view a copy of your results on GOV.UK](#{absolute_url})"
  end

  def is_a_brexit_checker_list?
    url =~ %r{transition-check/results} ||
      url =~ %r{get-ready-brexit-check/results}
  end
end
