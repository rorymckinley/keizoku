require 'spec_helper'
require 'date'
require 'keizoku/integration_queuer'

require 'keizoku/integration_scheduler'

RSpec::Matchers.define :be_integration_request do |expected|
  match do |actual|
    actual = actual.dup.tap { |o| o.delete(:queued_at) }
    actual == expected
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
  let(:integration_request) { {:workbench => "workbench_sprint666", :taggeremail => "sue@trial.co.za"} }
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
      enqueue(1, integration_request.merge( :workbench => "workbench_other" ), ->() { DateTime.new(1994) })
      enqueue(1, integration_request, ->() { DateTime.new(1984) })
      enqueue(1, integration_request, ->() { DateTime.new(1974) })
      enqueue(1, integration_request.merge( :taggeremail => "someoneelsemaybe@trial.co.za"))
      scheduler.read_queue
    end

    it "identifies the oldest request" do
      scheduler.oldest_request[:queued_at].should eq DateTime.new(1974)
    end

    it "identifies the next request for the tagger with the oldest request" do
      scheduler.next_integration_request[:queued_at].should eq DateTime.new(1984)
    end

    it "filters the next integration request if given a filter" do
      filter = ->(r) { r[:workbench] != "workbench_sprint666" }
      scheduler.next_integration_request(filter)[:queued_at].should eq DateTime.new(1994)
    end

    it "deletes all the tagger's requests for the selected workbench" do
      pending "not here yet"
    end
  end

end
