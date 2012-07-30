require 'spec_helper'
require 'keizoku/integration'

require 'keizoku/dispatcher'

RSpec::Matchers.define :be_busy_with do |request|
  match do |dispatcher|
    not dispatcher.accept_filter.call(request)
  end
end

describe Keizoku::Dispatcher do

  after(:each) do
    # Clean up unjoined threads from tests that don't cover full lifecycle
    @dispatcher.harvest_completed_integrations if @dispatcher
  end

  let(:request) { {:workbench => 'workbench_sprint66'} }
  let(:integration) { double(Keizoku::Integration, :request => request).as_null_object }
  let(:integration_factory) { ->(r) { integration } }

  describe "#start_integrating(request)" do

    it "adds an integration for the request to the pool" do
      @dispatcher = Keizoku::Dispatcher.new(1, integration_factory)
      @dispatcher.start_integrating(request)
      @dispatcher.should be_busy_with(request)
    end

    it "builds an integration for the request" do
      custom_validator = "keizoku-validate-minitest"
      Keizoku::Integration.should_receive(:build).with(request, custom_validator).and_return(double.as_null_object)
      @dispatcher = Keizoku::Dispatcher.new(1, ->(r) { Keizoku::Integration.build(r, custom_validator) })
      @dispatcher.start_integrating(request)
    end

    it "integrates the integration for the request" do
      integration = FakeIntegration.build(request)
      @dispatcher = Keizoku::Dispatcher.new(1, ->(r) { integration })
      @dispatcher.start_integrating(request)

      tempus_fugit

      integration.complete
      integration.should have_been_asked_to_integrate
    end
  end

  describe "#harvest_completed_integrations" do

    before(:each) do
      @integration = FakeIntegration.build(request)
      @dispatcher = Keizoku::Dispatcher.new(1, ->(r) { @integration })
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
      @dispatcher = Keizoku::Dispatcher.new(1, integration_factory)
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
      @dispatcher = Keizoku::Dispatcher.new(2, integration_factory)
      @dispatcher.start_integrating(request)
      @dispatcher.should_not be_full
    end

    it "is true when there is no capacity for another integration" do
      @dispatcher = Keizoku::Dispatcher.new(1, integration_factory)
      @dispatcher.start_integrating(request)
      @dispatcher.should be_full
    end

  end

  describe "#accept_filter" do

    before(:each) do
      @dispatcher = Keizoku::Dispatcher.new(1, integration_factory)
      @dispatcher.start_integrating(request)
    end
    let(:filter) { @dispatcher.accept_filter }

    it "gives a callable that is true for any request whose branch is not busy integrating" do
      filter.call({:workbench => 'workbench_another_sprint'}).should be_true
    end

    it "gives a callable that is false for any request whose branch is busy integrating" do
      filter.call({:workbench => request[:workbench]}).should be_false
    end

  end

end
