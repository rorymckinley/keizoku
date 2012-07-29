require 'spec_helper'
require 'date'
require 'uuid'
require 'keizoku/integration_queuer'

require 'keizoku/integration_scheduler'

RSpec::Matchers.define :be_integration_request do |expected|
  match do |actual|
    actual = actual.dup.tap { |o| o.delete(:queued_at) }
    actual == expected
  end
end

RSpec::Matchers.define :have_integration_requests_for_dates do |*dates|
  match do |scheduler|
    scheduler.requests.should have(dates.size).elements
    dates.each do |date|
      scheduler.requests.should be_any { |r| r[:queued_at] == date }
    end
  end
end

describe Keizoku::IntegrationScheduler do

  def clean_up_queue
    Dir.glob("/tmp/keizoku-*").each { |f| File.unlink(f) }
  end

  around(:each) do |example|
    clean_up_queue
    example.run
    clean_up_queue
  end

  let(:queuer) { Keizoku::IntegrationQueuer.new("/tmp") }
  let(:integration_request) { {:workbench => "workbench_sprint666", :taggeremail => "sue@trial.co.za"} }
  let(:scheduler) { Keizoku::IntegrationScheduler.new("/tmp") }

  def enqueue(quantity = 1, request = integration_request, clock = ->() { DateTime.now })
    quantity.times { queuer.enqueue(request, clock) }
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

  context "integration request lifecycle" do
    before(:each) do
      enqueue(1, integration_request.merge( :workbench => "workbench_other" ), ->() { DateTime.new(1994) })
      enqueue(1, integration_request, ->() { DateTime.new(1984) })
      enqueue(1, integration_request, ->() { DateTime.new(1974) })
      enqueue(1, integration_request.merge( :taggeremail => "someoneelsemaybe@trial.co.za"), ->() { DateTime.new(2004) })
      scheduler.read_queue
    end

    it "#next_integration_request returns the head of the earliest request timeline" do
      scheduler.next_integration_request[:queued_at].should eq DateTime.new(1984)
    end

    it "#next_integration_request excludes request timelines matching an optional filter" do
      filter = ->(r) { r[:workbench] != "workbench_sprint666" }
      scheduler.next_integration_request(filter)[:queued_at].should eq DateTime.new(1994)
    end

    it "#complete_integration_request deletes the request and its predecessors on the timeline" do
      request = scheduler.next_integration_request
      scheduler.complete_integration_request(request)
      scheduler.should have_integration_requests_for_dates DateTime.new(1994), DateTime.new(2004)

      scheduler = Keizoku::IntegrationScheduler.new("/tmp")
      scheduler.read_queue
      scheduler.should have_integration_requests_for_dates DateTime.new(1994), DateTime.new(2004)
    end

  end

  describe "when the queue empties" do
    before(:each) do
      enqueue
      scheduler.read_queue
      request = scheduler.next_integration_request
      scheduler.complete_integration_request(request)
    end

    it "#next_integration_request returns nil if the queue is empty" do
      scheduler.next_integration_request.should be_nil
    end

    it "#empty? is true" do
      scheduler.should be_empty
    end
  end

  describe "#empty?" do

    it "is true before the queue is read" do
      scheduler.should be_empty
    end

    it "is false when the queue is not empty" do
      enqueue
      scheduler.read_queue

      scheduler.should_not be_empty
    end

  end

end
