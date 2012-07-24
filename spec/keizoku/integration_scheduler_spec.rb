require 'spec_helper'

require 'keizoku/integration_queuer'
require 'ostruct'

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

    def oldest_request
      @requests.first
    end

    private

    def load_request(child)
      @requests << OpenStruct.new(attributes: Marshal.load(child.read), timestamp: child.mtime)
    end

    def sort_requests_by_ascending_timestamp
      @requests.sort! { |a, b| a.mtime <=> b.mtime }
    end

  end

end

describe Keizoku::IntegrationScheduler do

  def clean_up_queue
    Dir.glob("/tmp/keizoku-test-*").each { |f| File.unlink(f) }
  end

  around(:each) do |example|
    clean_up_queue
    example.run
    clean_up_queue
  end

  let(:filter) { ->(o) { "keizoku-test-#{rand(1000)}" } }
  let(:queuer) { Keizoku::IntegrationQueuer.new("/tmp", filter) }
  let(:integration_request) { {:some => :junk} }
  let(:scheduler) { Keizoku::IntegrationScheduler.new("/tmp", ->(o) { o =~ /keizoku-test-.+$/ }) }

  def enqueue(quantity = 1, request = integration_request)
    quantity.times { queuer.enqueue(request) }
  end

  it "is initialised with the path to the queue" do
    Keizoku::IntegrationScheduler.new("/tmp", ->() {}).should be_a Keizoku::IntegrationScheduler
  end

  it "enumerates all integration requests in the queue" do
    enqueue(2)
    scheduler.read_queue
    scheduler.requests.should have(2).things
  end

  it "deserializes integration requests" do
    enqueue
    scheduler.read_queue
    scheduler.requests.first.attributes.should eq integration_request
  end

  it "identifies the oldest request" do
    filter = ->(o) { "keizoku-test-#{o[:file_prefix]}#{rand(1000)}" }
    enqueue(1, :file_prefix => 'C')
    enqueue(1, :file_prefix => 'B')
    enqueue(1, :file_prefix => 'D')
    scheduler.read_queue
    scheduler.oldest_request.attributes.should eq(:file_prefix => 'C')
  end

end
