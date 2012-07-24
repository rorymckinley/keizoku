require 'spec_helper'

require 'keizoku/integration_queuer'

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
        @requests << child if @request_filter.call(child.basename.to_s)
      end
    end
  end
end

describe Keizoku::IntegrationScheduler do
  before(:each) do
    Dir.glob("/tmp/keizoku-test-*").each { |f| File.unlink(f) }
  end

  after(:each) do
    Dir.glob("/tmp/keizoku-test-*").each { |f| File.unlink(f) }
  end

  it "is initialised with the path to the queue" do
    Keizoku::IntegrationScheduler.new("/tmp", ->() {}).should be_a Keizoku::IntegrationScheduler
  end

  it "enumerates all integration requests in the queue" do
    queuer = Keizoku::IntegrationQueuer.new("/tmp", ->() { "keizoku-test-#{rand(1000)}" })
    2.times { queuer.enqueue(:some => :junk) }
    scheduler = Keizoku::IntegrationScheduler.new("/tmp", ->(o) { o =~ /keizoku-test-.+$/ })
    scheduler.read_queue
    scheduler.requests.should have(2).things
  end
end
