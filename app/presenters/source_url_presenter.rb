class SourceUrlPresenter < ApplicationPresenter
  def initialize(url)
    @url = url
  end

  def call
    return unless url =~ %r{transition-check/results}

    absolute_url = PublicUrls.url_for(base_path: url)
    "[You can view a copy of your results on GOV.UK](#{absolute_url})"
  end

private

  attr_reader :url
end
