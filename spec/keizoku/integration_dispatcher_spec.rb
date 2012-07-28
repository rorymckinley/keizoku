require 'spec_helper'

require 'support/fake_integration'

RSpec::Matchers.define :be_busy_with do |request|
  match do |dispatcher|
    not dispatcher.busy_filter.call(request)
  end
end

require 'keizoku/integration'

module Keizoku
  class IntegrationDispatcher

    def initialize(pool_size, integration_factory = ->(r) { Keizoku::Integration.build(r) })
      @integration_factory = integration_factory
      @pool_size = pool_size
      @integrations_in_progress = []
    end

    def start_integrating(request)
      integration = @integration_factory.call(request)
      @integrations_in_progress << integration
      integration.integrate
    end

    def empty?
      @integrations_in_progress.empty?
    end

    def full?
      @pool_size <= @integrations_in_progress.size
    end

    def busy_filter
      ->(request) { not busy_with?(request) }
    end

    private
    def busy_with?(request)
      @integrations_in_progress.detect { |integration| integration.request == request }
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
    let(:request) { {:workbench => 'workbench_sprint66'} }

    it "adds an integration for the request to the pool" do
      dispatcher = Keizoku::IntegrationDispatcher.new(1)
      dispatcher.start_integrating(request)
      dispatcher.should be_busy_with(request)
    end

    it "builds an integration for the request" do
      Keizoku::Integration.should_receive(:build).with(request).and_return(double.as_null_object)
      dispatcher = Keizoku::IntegrationDispatcher.new(1, ->(r) { Keizoku::Integration.build(r) })
      dispatcher.start_integrating(request)
    end

    it "integrates the integration for the request" do
      Keizoku::Integration.should_receive(:build).and_return(integration = double("integration"))
      integration.should_receive(:integrate)
      dispatcher = Keizoku::IntegrationDispatcher.new(1, ->(r) { Keizoku::Integration.build(r) })
      dispatcher.start_integrating(request)
    end
  end

  describe "#empty?" do

    it "is false when integrations are in progress" do
      dispatcher = Keizoku::IntegrationDispatcher.new(1)
      dispatcher.start_integrating({:workbench => 'workbench_sprint66'})
      dispatcher.should_not be_empty
    end

    it "is true before any integrations are received" do
      dispatcher = Keizoku::IntegrationDispatcher.new(1)
      dispatcher.should be_empty
    end

    it "is true after all integrations are completed"

  end

  describe "#full?" do

    it "is false when there is capacity for at least one more integration" do
      dispatcher = Keizoku::IntegrationDispatcher.new(2)
      dispatcher.start_integrating({:workbench => 'workbench_sprint66'})
      dispatcher.should_not be_full
    end

    it "is true when there is no capacity for another integration" do
      dispatcher = Keizoku::IntegrationDispatcher.new(1)
      dispatcher.start_integrating({:workbench => 'workbench_sprint66'})
      dispatcher.should be_full
    end

  end

  describe "#busy_filter" do

    let(:dispatcher) do
      Keizoku::IntegrationDispatcher.new(1).tap { |o| o.start_integrating({:workbench => 'workbench_sprint66'}) }
    end
    let(:filter) { dispatcher.busy_filter }

    it "gives a callable that is false for any branch that is integrating" do
      filter.call({:workbench => 'workbench_sprint66'}).should be_false
    end

    it "gives a callable that is true for any branch that is integrating" do
      filter.call({:workbench => 'workbench_another_sprint'}).should be_true
    end

  end

end
