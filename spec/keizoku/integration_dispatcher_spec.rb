require 'spec_helper'
require 'keizoku/integration_scheduler'
require 'keizoku/integration'

module Keizoku
  class IntegrationDispatcher
    def initialize(scheduler, integration_factory, notifier = nil)
      @scheduler = scheduler
      @integration_factory = integration_factory
      @notifier = notifier
    end

    def run
      @scheduler.read_queue
      while request = @scheduler.next_integration_request
        integration = @integration_factory.build(request)
        integration.integrate
        @scheduler.complete_integration_request(request)
        @notifier.notify(integration) if @notifier
      end
    end
  end
end

class FakeScheduler
  attr_accessor :requests

  def initialize(requests)
    @queued_requests = requests.dup
  end

  def read_queue
    @requests = @queued_requests.dup
    @queued_requests.clear
  end

  def next_integration_request
    @requests.first
  end

  def complete_integration_request(request)
    @requests.delete(request)
  end
end

describe Keizoku::IntegrationDispatcher do
  it "kicks off integrations until the scheduler is empty" do
    request1 = {:some => :junk}
    request2 = {:other => :stuff}
    scheduler = FakeScheduler.new([request1, request2])
    dispatcher = Keizoku::IntegrationDispatcher.new(scheduler, integrator = double)

    integrator.should_receive(:build).with(request1).and_return(integration1 = double)
    integrator.should_receive(:build).with(request2).and_return(integration2 = double)
    integration1.should_receive(:integrate)
    integration2.should_receive(:integrate)

    dispatcher.run

    scheduler.requests.should be_empty
  end

  it "triggers notification of each integration outcome" do
    scheduler = FakeScheduler.new([{:some => :junk}])
    dispatcher = Keizoku::IntegrationDispatcher.new(scheduler, Keizoku::Integration, notifier = double)
    notifier.stub(:notify).with(an_instance_of(Keizoku::Integration))

    dispatcher.run
  end

end
