require 'spec_helper'

module Keizoku
  class IntegrationDispatcher

    def initialize(pool_size)
      @requests = []
    end

    def start_integrating(request)
      @requests << request
    end

    def busy_with?(request)
      @requests.include?(request)
    end

  end
end

describe Keizoku::IntegrationDispatcher do

  describe "#new(pool_size)" do

    it "it takes a pool size" do
      expect { Keizoku::IntegrationDispatcher.new(1) }.to_not raise_error
    end

  end

  describe "#start_integrating(request)" do

    it "adds an integration for the request to the pool" do
      dispatcher = Keizoku::IntegrationDispatcher.new(1)
      dispatcher.start_integrating({:workbench => 'workbench_sprint66'})
      dispatcher.should be_busy_with({:workbench => 'workbench_sprint66'})
    end

  end

  def pidlog(message)
    $stderr.puts "[#{Process.pid}] #{message}"
  end

  class FakeIntegration

    def initialize(io)
      @io = io
    end
    def integrate(request)
      @io.gets
      pidlog "Got it, boss, we're outta here"
    end
    def pidlog(message)
      $stderr.puts "[#{Process.pid}] #{message}"
    end
  end

  describe "fake integration" do
    it "works" do
      r, w = IO.pipe
      i = FakeIntegration.new(r)
      Process.fork { i.integrate(nil); pidlog "leaving fork" }
      sleep 0.1
      Process.wait(-1, Process::WNOHANG).should be_nil
      w.puts
      w.flush
      sleep 0.1
      Process.wait(-1, Process::WNOHANG).should_not be_nil
    end
  end

end
