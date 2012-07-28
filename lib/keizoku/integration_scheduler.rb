module Keizoku

  class IntegrationScheduler

    attr_reader :requests

    def initialize(queue_path, basename_filter)
      @queue_path = Pathname.new(queue_path)
      @basename_filter = basename_filter
      empty_requests_and_paths
    end

    def read_queue
      empty_requests_and_paths
      @queue_path.each_child do |child|
        load_request(child) if @basename_filter.call(child.basename.to_s)
      end
      sort_requests_by_ascending_timestamp
    end

    def oldest_request(filter = Proc.new { true })
      @requests.detect { |request| filter.call(request) }
    end

    def next_integration_request(filter = Proc.new { true })
      oldest_filtered_request = oldest_request(filter)
      @requests.reverse.detect do |request|
        same_taggeremail_and_workbench?(request, oldest_filtered_request)
      end
    end

    def complete_integration_request(completed_request)
      @requests.delete_if do |request|
        completed_request_obsoletes_request?(completed_request, request) and remove_request_from_queue(request)
      end
    end

    def empty?
      @requests.empty?
    end

    private

    def empty_requests_and_paths
      @requests = []
      @request_paths = {}
    end

    def sort_requests_by_ascending_timestamp
      @requests.sort! { |a, b| a[:queued_at] <=> b[:queued_at] }
    end

    def completed_request_obsoletes_request?(completed_request, request)
      same_taggeremail_and_workbench?(request, completed_request) and request[:queued_at] <= completed_request[:queued_at]
    end

    def same_taggeremail_and_workbench?(a, b)
      [ :taggeremail, :workbench ].all? { |key| a[key] == b[key] }
    end

    def load_request(child)
      @requests << Marshal.load(child.read)
      @request_paths[@requests.last.object_id] = child
    end

    def remove_request_from_queue(request)
      @request_paths[request.object_id].unlink
    end

  end

end

