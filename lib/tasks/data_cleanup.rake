desc "Update one of the tags in a subscriber list"
task delete_bad_lists: :environment do |_t, _args|
  BadListDeleter::VALID_PREFIXES.each do |prefix|
    deleter = BadListDeleter.new(prefix)

    bad_lists = deleter.bad_lists
    subscriptions_sum = bad_lists.sum { |l| l.subscriptions.ended.count }
    puts "Prefix: #{prefix} attempting to delete #{bad_lists.count} lists and #{subscriptions_sum} subscriptions"
    deleter.process_all_lists
    puts " - #{deleter.bad_lists.count} could not be deleted" if deleter.bad_lists.any?
  end
end
