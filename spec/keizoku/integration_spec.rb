require 'spec_helper'
require 'keizoku/integration'

describe Keizoku::Integration do
  let(:request) { {:keizoku_is_awesome => "junk", :keizoku_is_testing => "stuff"} }
  let(:integration_script) { File.join(File.dirname(__FILE__), '..', 'support', 'fake-keizoku-integration') }
  let(:integration) { Keizoku::Integration.build(request, '/bin/true', integration_script) }

  describe ".build(request)" do
    it "returns an integration for the request" do
      integration.request.should eq request
    end
  end

  describe "#integrate" do
    before(:each) { integration.integrate }

    it "defines a request-specific environment for the integration script" do
      integration.log.should include("KEIZOKU_IS_AWESOME=junk")
      integration.log.should include("KEIZOKU_IS_TESTING=stuff")
    end

    it "does not touch the process environment" do
      request.each { |key, value| ENV.should_not include(key.to_s.upcase) }
    end

    it "it includes the process environment in the environment it defines for the integration script" do
      integration.log.should include("PATH=#{ENV['PATH']}")
    end
  end

  describe "#log" do
    it "makes a log of the integration attempt available" do
      integration = Keizoku::Integration.build(request, "/bin/echo Wonderful success", integration_script)
      integration.integrate
      integration.log.should match(/Wonderful success/)
    end

    it "logs an error if the integration script is not executable" do
      integration = Keizoku::Integration.build(request, "/bin/true", 'nonexistent-integration-helper')
      expect { integration.integrate }.to_not raise_error
      integration.log.should include('command not found')
    end
  end

  describe "#completed?" do
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
      integration.integrate
      integration.should be_successful
    end

    it "is false when the integration script was not successful" do
      integration = Keizoku::Integration.build(request, "/bin/false", integration_script)
      integration.integrate
      integration.should_not be_successful
    end
  end
end
