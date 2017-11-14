require_relative "extensions/symbolize_json"

class ContentChange < ApplicationRecord
  include SymbolizeJSON
end
