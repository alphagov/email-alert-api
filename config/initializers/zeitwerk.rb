Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "symbolize_json" => "SymbolizeJSON",
    "email_alert_api" => "EmailAlertAPI",
  )
end
