desc "Convert all legacy subscriber lists to the new format"
task convert_legacy_subscriber_lists: :environment do
  LegacyConversionService.call
end

task revert_legacy_subscriber_lists: :environment do
  LegacyConversionService.uncall
end
