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
end
