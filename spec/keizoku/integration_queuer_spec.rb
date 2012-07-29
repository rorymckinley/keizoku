require 'spec_helper'
require 'date'

require 'keizoku/integration_queuer'

describe Keizoku::IntegrationQueuer do

  after(:all) { Dir.glob('/tmp/keizoku-*').each { |f| File.unlink(f) } }

  let(:queuer) { Keizoku::IntegrationQueuer.new("/tmp") }
  let(:integration_request) { { :some => :junk } }

  it "returns the path of the file into which the request was enqueued" do
    queuer.enqueue(integration_request)
    queuer.request_path.should be_a Pathname
  end

  it "includes the queue directory in the path of the created file" do
    queuer.enqueue(integration_request)
    queuer.request_path.dirname.should eq queuer.queue_path
  end

  it "uses a universally unique filename" do
    UUID.stub(:generate).and_return ('uuid')
    queuer.enqueue(integration_request)
    queuer.request_path.basename.should eq Pathname.new('keizoku-uuid')
  end

  it "writes the request into a file in the queue directory" do
    queuer.enqueue(integration_request)
    queuer.request_path.should exist
  end

  it "writes the contents of the request into the file" do
    queuer.enqueue(integration_request)
    queuer.request_path.binread.should eq Marshal.dump(queuer.last_enqueued_request)
  end

  it "includes time of receipt (to nanosecond resolution) in the request" do
    very_specific_time = DateTime.new(2012,07,25,20,51,0.0042)
    queuer.enqueue(integration_request, ->() { very_specific_time })
    queuer.last_enqueued_request[:queued_at].should eq very_specific_time
  end

end
