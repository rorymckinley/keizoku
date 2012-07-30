require 'spec_helper'
require 'keizoku/integration'

describe Keizoku::Integration do
  let(:request) { {:keizoku_is_awesome => "junk", :keizoku_is_testing => "stuff"} }
  let(:integration) { Keizoku::Integration.build(request, "keizoku-validate-rake-spec") }

  describe ".build(request)" do
    it "returns an integration for the request" do
      integration.request.should eq request
    end
  end

  describe "#integrate" do
    it "defines a request-specific environment for the integration script" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      @integration = Keizoku::Integration.build(request, "/bin/true", helper)
      @integration.integrate
      @integration.log.should include("KEIZOKU_IS_AWESOME=junk")
      @integration.log.should include("KEIZOKU_IS_TESTING=stuff")
    end

    it "does not touch the process environment" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      @integration = Keizoku::Integration.build(request, "/bin/true", helper)
      @integration.integrate
      request.each { |key, value| ENV.should_not include(key.to_s.upcase) }
    end

    it "it includes the process environment in the environment it defines for the integration script" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      @integration = Keizoku::Integration.build(request, "/bin/true", helper)
      @integration.integrate
      @integration.log.should include("PATH=#{ENV['PATH']}")
    end

    it "raises an error if the integration script is not executable" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'does_not_exist')
      @integration = Keizoku::Integration.build(request, "/bin/true", helper)
      expect { @integration.integrate }.to raise_error
    end

    # TODO this must go when integration tests prove system() is working
    it "it works with an actual integration helper and real fork, with successful integration" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      integrations = [1, 2].collect { Keizoku::Integration.build(request, "/bin/true", helper) }
      threads = integrations.collect { |i| Thread.fork { i.integrate } }
      sleep 0.025
      threads.each { |t| t.join }
      integrations.each do |i|
        i.should be_completed
        i.should be_successful
      end
    end

    # TODO this must go when integration tests prove system() is working
    it "it works with an actual integration helper and real fork, with failed integration" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      integrations = [1, 2].collect { Keizoku::Integration.build(request, "/bin/false", helper) }
      threads = integrations.collect { |i| Thread.fork { i.integrate } }
      sleep 0.025
      threads.each { |t| t.join }
      integrations.each do |i|
        i.should be_completed
        i.should_not be_successful
      end
    end

    it "makes a log of the integration attempt avaialble" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      @integration = Keizoku::Integration.build(request, "/bin/echo Wonderful success", helper)
      thr = Thread.fork { @integration.integrate }
      sleep 0.025
      thr.join
      @integration.log.should match(/Wonderful success/)
    end
  end

  describe "#completed?" do
    it "is false if not completed" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      @integration = Keizoku::Integration.build(request, "/bin/true", helper)
      @integration.should_not be_completed
    end

    it "is true if completed (regardless of integration outcome)" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      @integration = Keizoku::Integration.build(request, "/bin/true", helper)
      @integration.integrate
      @integration.should be_completed
    end
  end

  describe "#successful?" do
    it "is true when the integration script was successful" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      @integration = Keizoku::Integration.build(request, "/bin/true", helper)
      @integration.integrate
      @integration.should be_successful
    end

    it "is false when the integration script was not successful" do
      helper = File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration')
      @integration = Keizoku::Integration.build(request, "/bin/false", helper)
      @integration.integrate
      @integration.should_not be_successful
    end
  end
end
