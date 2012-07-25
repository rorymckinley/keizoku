require 'spec_helper'
require 'date'

require 'keizoku/integration_queuer'
require 'ostruct'

RSpec::Matchers.define :be_integration_request do |expected|
  match do |actual|
    actual = actual.dup.tap { |o| o.delete(:queued_at) }
    actual == expected
  end
end

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

    def next_integration_request
      @requests.reverse.detect { |request| request[:taggeremail] == oldest_request[:taggeremail] }
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

describe Keizoku::IntegrationScheduler do

  def clean_up_queue
    Dir.glob("/tmp/keizoku-test-*").each { |f| File.unlink(f) }
  end

  around(:each) do |example|
    clean_up_queue
    example.run
    clean_up_queue
  end

  let(:generator) { ->(o) { "keizoku-test-#{rand(1000)}" } }
  let(:queuer) { Keizoku::IntegrationQueuer.new("/tmp", generator) }
  let(:integration_request) { {:some => :junk, :taggeremail => "sue@trial.co.za"} }
  let(:scheduler) { Keizoku::IntegrationScheduler.new("/tmp", ->(o) { o =~ /keizoku-test-.+$/ }) }

  def enqueue(quantity = 1, request = integration_request, clock = ->() { DateTime.now })
    quantity.times { queuer.enqueue(request, clock) }
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
    scheduler.requests.first.should be_integration_request integration_request
  end

  context "finding the request to integrate" do
    before(:each) do
      enqueue(1, integration_request, ->() { DateTime.new(1984,10,18,06,40,00) })
      enqueue(1, integration_request, ->() { DateTime.new(1974,10,18,06,40,00) })
      enqueue(1, integration_request.merge( :taggeremail => "bob@trial.co.za"))
      scheduler.read_queue
    end

    it "identifies the oldest request" do
      scheduler.oldest_request[:queued_at].should eq DateTime.new(1974,10,18,06,40,00)
    end

    it "identifies the next request for the tagger with the oldest request" do
      scheduler.next_integration_request[:queued_at].should eq DateTime.new(1984,10,18,06,40,00)
    end
  end

end
