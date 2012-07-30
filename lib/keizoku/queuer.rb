require 'date'
require 'pathname'
require 'uuid'

module Keizoku

  class Queuer
    attr_reader :queue_path, :request_path

    def initialize(queue_path, filename_generator = ->(o) { "keizoku-#{UUID.generate}" })
      @queue_path = Pathname.new(queue_path)
      @filename_generator = filename_generator
    end

    def enqueue(request, clock = ->() { DateTime.now })
      @request = request.merge(:queued_at => clock.call)
      set_unique_request_path
      write_request
    end

    def last_enqueued_request
      @request
    end

    private

    def set_unique_request_path
      @request_path = @queue_path + Pathname.new(@filename_generator.call(@request))
    end

    def write_request
      @request_path.open('wb') { |io| io.write serialized_request }
    end

    def serialized_request
      Marshal.dump @request
    end
  end
end
