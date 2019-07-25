module Clean
  class EmptySubscriberLists
    def lists
      @lists ||= SubscriberList.all.select { |l| l.subscriptions.count.zero? }
    end

    def remove_empty_subscriberlists(dry_run: true)
      lists.each(&:destroy) unless dry_run
      puts "Found #{dry_run ? '' : 'and removed '}#{lists.count} #{'lists'.pluralize(lists.count)} that had no subscribers"
    end
  end
end
