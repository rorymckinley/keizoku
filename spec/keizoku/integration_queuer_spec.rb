require 'spec_helper'

require 'keizoku/integration_queuer'

describe Keizoku::IntegrationQueuer do

  after(:all) { Dir.glob('/tmp/keizoku-test-*').each { |f| File.unlink(f) } }

  let(:filename_generator) { ->() { "keizoku-test-" + rand(1000).to_s } }
  let(:queuer) { Keizoku::IntegrationQueuer.new("/tmp", filename_generator) }
  let(:integration_request) { { :some => :junk } }

  it "initialises with a directory name" do
    Keizoku::IntegrationQueuer.new("/tmp").should be_a Keizoku::IntegrationQueuer
  end

  it "returns the path of the file into which the request was enqueued" do
    queuer.enqueue(integration_request)
    queuer.request_path.should be_a Pathname
  end

  it "includes the queue directory in the path of the created file" do
    queuer.enqueue(integration_request)
    queuer.request_path.dirname.should eq queuer.queue_path
  end

  it "uses a universally unique filename" do
    predictable_generator = ->() { "e460e540-b7f1-012f-a3e4-001b215da155" }
    queuer = Keizoku::IntegrationQueuer.new("/tmp", predictable_generator)
    queuer.enqueue(integration_request)
    queuer.request_path.basename.should eq Pathname.new(predictable_generator.call)
  end

  it "writes the request into a file in the queue directory" do
    queuer.enqueue(integration_request)
    queuer.request_path.should exist
  end

  it "writes the contents of the request into the file" do
    queuer.enqueue(integration_request)
    queuer.request_path.read.should eq Marshal.dump(integration_request)
  end
end
