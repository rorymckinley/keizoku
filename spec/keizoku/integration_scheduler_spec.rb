require 'spec_helper'

# For the class
require 'pathname'
require 'fileutils'
require 'uuid'

module Keizoku

  class IntegrationScheduler
    attr_reader :queue_path, :request_path

    def initialize(queue_path, filename_generator = ->() { UUID.generate })
      @queue_path = Pathname.new(queue_path)
      @filename_generator = filename_generator
    end

    def schedule(request)
      set_unique_request_path
      write_request
    end

    private

    def set_unique_request_path
      @request_path = @queue_path + Pathname.new(@filename_generator.call)
    end

    def write_request
      @request_path.open('w') { |io| io.puts }
    end

  end
end

describe Keizoku::IntegrationScheduler do

  after(:all) { Dir.glob('/tmp/keizoku-test-*').each { |f| File.unlink(f) } }

  let(:filename_generator) { ->() { "keizoku-test-" + rand(1000).to_s } }
  let(:scheduler) { Keizoku::IntegrationScheduler.new("/tmp", filename_generator) }
  let(:integration_request) { { :some => :junk } }

  it "initialises with a directory name" do
    Keizoku::IntegrationScheduler.new("/tmp").should be_a Keizoku::IntegrationScheduler
  end

  it "returns the path of the file into which the request was scheduled" do
    scheduler.schedule(integration_request)
    scheduler.request_path.should be_a Pathname
  end

  it "includes the queue directory in the path of the created file" do
    scheduler.schedule(integration_request)
    scheduler.request_path.dirname.should eq scheduler.queue_path
  end

  it "uses a universally unique filename" do
    preditable_generator = ->() { "e460e540-b7f1-012f-a3e4-001b215da155" }
    scheduler = Keizoku::IntegrationScheduler.new("/tmp", preditable_generator)
    scheduler.schedule(integration_request)
    scheduler.request_path.basename.should eq Pathname.new(preditable_generator.call)
  end

  it "writes the request into a file in the queue directory" do
    scheduler.schedule(integration_request)
    scheduler.request_path.should exist
  end

end
