require 'spec_helper'
require 'keizoku/integration'

describe Keizoku::Integration do
  let(:request) { {:some => :junk} }
  let(:integration) { Keizoku::Integration.build(request) }

  describe ".build(request)" do
    it "returns an integration for the request" do
      integration.request.should eq request
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
end
