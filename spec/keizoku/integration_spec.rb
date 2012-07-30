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
    it "executes the integration script" do
      integration.should_receive(:system).with(anything, "keizoku-integrate").and_return(true)
      integration.integrate
    end

    it "defines a repo-specific environment for the integration script" do
      integration.should_receive(:system) { |env, command| env['VALIDATOR'].should == "keizoku-validate-rake-spec" }
      integration.integrate
    end

    it "defines a request-specific environment for the integration script" do
      integration.should_receive(:system) do |env, command|
        env['KEIZOKU_IS_AWESOME'].should == "junk"
        env['KEIZOKU_IS_TESTING'].should == "stuff"
      end
      integration.integrate
    end

    it "does not touch the process environment" do
      integration.should_receive(:system).and_return(true)
      integration.integrate
      request.each { |key, value| ENV.should_not include(key.to_s.upcase) }
    end

    it "it includes the process environment in the environment it defines for the integration script" do
      integration.should_receive(:system) { |env, command| env['PATH'].should == ENV['PATH'] }
      integration.integrate
    end

    it "raises an error if the integration script could not be executed" do
      integration.should_receive(:system).and_return(nil)
      expect { integration.integrate }.to raise_error
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
  end

  describe "#completed?" do
    before(:each) do
      integration.stub(:system).and_return(true)
    end

    it "is false if not completed" do
      integration.should_not be_completed
    end

    it "is true if completed (regardless of integration outcome)" do
      integration.integrate
      integration.should be_completed
    end
  end

  describe "#successful?" do
    it "is true when the integration script was successful" do
      integration.should_receive(:system).and_return(true)
      integration.integrate
      integration.should be_successful
    end

    it "is false when the integration script was not successful" do
      integration.should_receive(:system).and_return(false)
      integration.integrate
      integration.should_not be_successful
    end
  end
end
