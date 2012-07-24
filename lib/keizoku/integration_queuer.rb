require 'pathname'
require 'uuid'

module Keizoku

  class IntegrationQueuer
    attr_reader :queue_path, :request_path

    def initialize(queue_path, filename_generator = ->() { UUID.generate })
      @queue_path = Pathname.new(queue_path)
      @filename_generator = filename_generator
    end

    def enqueue(request)
      @request = request
      set_unique_request_path
      write_request
    end

    private

    def set_unique_request_path
      @request_path = @queue_path + Pathname.new(@filename_generator.call)
    end

    def write_request
      @request_path.open('w') { |io| io.write serialized_request }
    end

    def serialized_request
      Marshal.dump @request
    end
  end
end
