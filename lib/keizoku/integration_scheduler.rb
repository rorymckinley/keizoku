module Keizoku

  class IntegrationScheduler

    attr_reader :requests

    def initialize(queue_path, request_filter)
      @queue_path = Pathname.new(queue_path)
      @request_filter = request_filter
    end

    def read_queue
      @requests = []
      @queue_path.each_child do |child|
        load_request(child) if @request_filter.call(child.basename.to_s)
      end
      sort_requests_by_ascending_timestamp
    end

    def oldest_request(filter = Proc.new { true })
      @requests.detect { |request| filter.call(request) }
    end

    def next_integration_request(filter = Proc.new { true })
      oldest_filtered_request = oldest_request(filter)
      @requests.reverse.detect do |request|
        [ :taggeremail, :workbench ].all? { |key| request[key] == oldest_filtered_request[key] }
      end
    end

    private

    def load_request(child)
      @requests << Marshal.load(child.read)
    end

    def sort_requests_by_ascending_timestamp
      @requests.sort! { |a, b| a[:queued_at] <=> b[:queued_at] }
    end

  end

end

