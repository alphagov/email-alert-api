desc "Convert all legacy subscriber lists to the new format"
task :convert_legace_subscriber_lists, :environment do
  LegacyConversionService.call
end
