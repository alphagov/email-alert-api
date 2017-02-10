require 'thread'

module DataHygiene
  class DeleteTopicsWithoutSubscribers
    attr_reader :client
    delegate :puts, to: :@output
    delegate :gets, to: :@input

    def initialize(client: Services.gov_delivery, input: STDIN, output: STDOUT)
      @client = client
      @input = input
      @output = output
    end

    def call
      puts "#{with_zero_subscribers.count} subscriber lists without subscribers"
      with_zero_subscribers.each { |sl| puts "#{sl.gov_delivery_id} - #{sl.title}"}
      if with_gov_delivery_error.count > 0
        puts ''
        puts "#{with_gov_delivery_error.count} subscriber lists with errors - THESE ARE NOT BEING DELETED"
        with_gov_delivery_error.each { |sl| puts "#{sl.gov_delivery_id} - #{sl.title}"}
      end

      puts ''
      puts "#{with_zero_subscribers.count} subscriber lists without subscribers, enter `delete` to delete from database and GovDelivery: "
      command = gets

      if command.chomp == 'delete'
        with_zero_subscribers.each do |subscriber_list|
          delete_topic(subscriber_list)
        end
      end
    end

    def subscriber_lists
      @subscriber_lists ||= ThreadedSubscriberCountRetriever.new(client: client, output: @output).call
    end

    def with_zero_subscribers
      @with_zero_subscribers ||= subscriber_lists
        .select { |c, s| c&.zero? }
        .map(&:last)
    end

    def with_gov_delivery_error
      @with_gov_delivery_error ||= subscriber_lists
        .select { |c, s| c.nil? }
        .map(&:last)
    end

  private

    def subscriber_count(gov_delivery_id)
      topic = client.fetch_topic(gov_delivery_id)
      topic && topic['subscribers_count']
    rescue GovDelivery::Client::UnknownError
      nil
    end

    def delete_topic(subscriber_list)
      subscribers = subscriber_count(subscriber_list.gov_delivery_id)

      if subscribers.nil?
        puts "Skipping #{subscriber_list.gov_delivery_id} as it does not appear on GovDelivery"
      elsif subscribers.zero?
        puts "Deleting: #{subscriber_list.gov_delivery_id}"
        delete_topic_with_error_catching(subscriber_list.gov_delivery_id)
        SubscriberList.where(gov_delivery_id: subscriber_list.gov_delivery_id).delete_all
      else
        puts "Skipping #{subscriber_list.gov_delivery_id} as it now has #{subscribers} subscribers"
      end
    end

    def delete_topic_with_error_catching(gov_delivery_id)
      client.delete_topic(gov_delivery_id)
    rescue GovDelivery::Client::UnknownError
      puts "---- Error deleting: #{gov_delivery_id}"
    end

    class ThreadedSubscriberCountRetriever
      MAX_THREAD_COUNT = 40
      MIN_BATCH_SIZE = 10

      attr_reader :client
      delegate :puts, :print, to: :@output

      def initialize(client: nil, output: STDOUT)
        @client = client
        @output = output
      end

      def call
        group_size = [(SubscriberList.count.to_f / MAX_THREAD_COUNT).ceil, MIN_BATCH_SIZE].max
        subscriber_list_sets = SubscriberList.all.each_slice(group_size)

        results = []
        semaphore = Mutex.new
        threads = subscriber_list_sets.map do |subscriber_list_set|
          Thread.new do
            results_for_thread = add_count_of_subscribers(subscriber_list_set)
            semaphore.synchronize { results += results_for_thread }
          end
        end
        threads.each(&:join)
        puts ''
        results
      end

      def add_count_of_subscribers(subscriber_lists)
        subscriber_lists.map do |subscriber_list|
          print '.'
          [subscriber_count(subscriber_list.gov_delivery_id), subscriber_list]
        end
      end

      def subscriber_count(gov_delivery_id)
        topic = client.fetch_topic(gov_delivery_id)
        topic && topic['subscribers_count']
      rescue GovDelivery::Client::UnknownError
        nil
      end
    end
  end
end
