require 'spec_helper'
require 'keizoku/integration'

describe Keizoku::Integration do
  describe ".build(request)" do
    it "returns an integration for the request" do
      request = {:some => :junk}
      integration = Keizoku::Integration.build(request)
      integration.request.should eq request
    end
  end

  describe "#integrate" do
    it "exists" do
      request = {:some => :junk}
      integration = Keizoku::Integration.build(request)
      expect { integration.integrate }.to_not raise_error
    end
  end

  describe "#completed?" do
    it "is false if not completed" do
      request = {:some => :junk}
      integration = Keizoku::Integration.build(request)
      integration.should_not be_completed
    end

    it "is true if completed (regardless of integration outcome)" do
      request = {:some => :junk}
      integration = Keizoku::Integration.build(request)
      integration.integrate
      integration.should be_completed
    end
  end
end
