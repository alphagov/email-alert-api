require_relative "extensions/symbolize_json"

class Notification < ApplicationRecord
  include SymbolizeJSON
end
