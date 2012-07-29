require 'spec_helper'
require 'keizoku/integration'

require 'keizoku/integration_dispatcher'

RSpec::Matchers.define :be_busy_with do |request|
  match do |dispatcher|
    not dispatcher.busy_filter.call(request)
  end
end

# To accommodate a small delay when working with threads
def tempus_fugit
  sleep 0.005
end

describe Keizoku::IntegrationDispatcher do

  after(:each) do
    # An optimisation to catch any unjoined threads
    @dispatcher.harvest_completed_integrations if @dispatcher
  end

  let(:request) { {:workbench => 'workbench_sprint66'} }

  describe "#start_integrating(request)" do

    it "adds an integration for the request to the pool" do
      @dispatcher = Keizoku::IntegrationDispatcher.new(1)
      @dispatcher.start_integrating(request)
      @dispatcher.should be_busy_with(request)
    end

    it "builds an integration for the request" do
      Keizoku::Integration.should_receive(:build).with(request).and_return(double.as_null_object)
      @dispatcher = Keizoku::IntegrationDispatcher.new(1, ->(r) { Keizoku::Integration.build(r) })
      @dispatcher.start_integrating(request)
    end

    it "integrates the integration for the request" do
      integration = FakeIntegration.build(request)
      @dispatcher = Keizoku::IntegrationDispatcher.new(1, ->(r) { integration })
      @dispatcher.start_integrating(request)

      tempus_fugit

      integration.complete
      integration.should have_been_asked_to_integrate
    end
  end

  describe "#harvest_completed_integrations" do

    before(:each) do
      @integration = FakeIntegration.build(request)
      @dispatcher = Keizoku::IntegrationDispatcher.new(1, ->(r) { @integration })
      @dispatcher.start_integrating(request)
    end

    it "returns an empty array if no integrations have been completed since last call" do
      @dispatcher.harvest_completed_integrations.should be_empty
    end

    it "returns the integrations completed since last call" do
      @integration.complete

      @dispatcher.harvest_completed_integrations.should include(@integration)
      @dispatcher.harvest_completed_integrations.should be_empty
    end

  end

  describe "#empty?" do
    before(:each) do
      @dispatcher = Keizoku::IntegrationDispatcher.new(1)
    end

    it "is false when integrations are in progress" do
      @dispatcher.start_integrating(request)
      @dispatcher.should_not be_empty
    end

    it "is true before any integrations are received" do
      @dispatcher.should be_empty
    end

    it "is true after all integrations are completed" do
      @dispatcher.start_integrating(request)

      tempus_fugit

      @dispatcher.harvest_completed_integrations
      @dispatcher.should be_empty
    end

  end

  describe "#full?" do

    it "is false when there is capacity for at least one more integration" do
      @dispatcher = Keizoku::IntegrationDispatcher.new(2)
      @dispatcher.start_integrating(request)
      @dispatcher.should_not be_full
    end

    it "is true when there is no capacity for another integration" do
      @dispatcher = Keizoku::IntegrationDispatcher.new(1)
      @dispatcher.start_integrating(request)
      @dispatcher.should be_full
    end

  end

  describe "#busy_filter" do

    before(:each) do
      @dispatcher = Keizoku::IntegrationDispatcher.new(1).tap { |o| o.start_integrating(request) }
    end
    let(:filter) { @dispatcher.busy_filter }

    it "gives a callable that is false for any branch that is integrating" do
      filter.call(request).should be_false
    end

    it "gives a callable that is true for any branch that is integrating" do
      filter.call({:workbench => 'workbench_another_sprint'}).should be_true
    end

  end

end
