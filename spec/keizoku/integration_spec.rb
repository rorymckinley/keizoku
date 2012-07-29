require 'spec_helper'
require 'keizoku/integration'

describe Keizoku::Integration do
  let(:request) { {:some => "junk", :more => "stuff"} }
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
      integration.should_receive(:system) do |*args|
        env = args.first
        env['VALIDATOR'].should == "keizoku-validate-rake-spec"
      end
      integration.integrate
    end

    it "defines a request-specific environment for the integration script" do
      integration.should_receive(:system) do |*args|
        env = args.first
        env['SOME'].should == "junk"
        env['MORE'].should == "stuff"
      end
      integration.integrate
    end

    it "raises an error if the integration script could not be executed" do
      integration.should_receive(:system).and_return(nil)
      expect { integration.integrate }.to raise_error
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
