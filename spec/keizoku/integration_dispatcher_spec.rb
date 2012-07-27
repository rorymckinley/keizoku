require 'spec_helper'
require 'keizoku/integration_scheduler'
require 'keizoku/integration'

module Keizoku
  class IntegrationDispatcher
    def initialize(scheduler, integration_factory, notifier)
      @scheduler = scheduler
      @integration_factory = integration_factory
      @notifier = notifier
    end

    def run
      @scheduler.read_queue
      request = @scheduler.next_integration_request
      integration = @integration_factory.build(request)
      integration.integrate
      @notifier.notify(integration)
    end
  end
end

describe Keizoku::IntegrationDispatcher do
  let(:request) { {:some => :junk} }
  let(:scheduler) do
    double(Keizoku::IntegrationScheduler, :next_integration_request => request).as_null_object
  end
  let(:notifier) { double(:FakeNotifier).as_null_object }
  let(:dispatcher) do
    Keizoku::IntegrationDispatcher.new(scheduler, Keizoku::Integration, notifier)
  end

  it "tells the scheduler to read the queue" do
    scheduler.should_receive(:read_queue)
    dispatcher.run
  end

  it "kicks off the next integration request" do
    integration = double(Keizoku::Integration).as_null_object
    integration.should_receive(:integrate)
    Keizoku::Integration.stub(:build).with(request).and_return(integration)

    dispatcher.run
  end

  it "triggers notification of each integration outcome" do
    integration = double(Keizoku::Integration).as_null_object
    Keizoku::Integration.stub(:build).and_return(integration)
    notifier.should_receive(:notify).with(integration)

    dispatcher.run
  end

  it "makes repeated calls to the scheduler until there are no remaining integration requests" do
    scheduler = double(Keizoku::IntegrationScheduler).as_null_object
    scheduler.should_receive(:next_integration_request).and_return(request, nil)

    dispatcher.run
  end
end
