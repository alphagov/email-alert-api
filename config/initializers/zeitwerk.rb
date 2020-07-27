Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "symbolize_json" => "SymbolizeJSON",
  )
end
