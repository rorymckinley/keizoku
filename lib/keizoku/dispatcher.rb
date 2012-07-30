module Keizoku
  class Dispatcher

    def initialize(pool_size, integration_factory = ->(r) { Keizoku::Integration.build(r) })
      @integration_factory = integration_factory
      @pool_size = pool_size
      @integrations_in_progress = {}
    end

    def start_integrating(request)
      integration = @integration_factory.call(request)
      @integrations_in_progress[integration] = Thread.fork { integration.integrate }
    end

    def harvest_completed_integrations
      @completed_integrations = []
      @integrations_in_progress.each_key do |integration|
        reap_integration(integration) if integration.completed?
      end
      @completed_integrations
    end

    def reap_integration(integration)
      @completed_integrations << integration
      @integrations_in_progress.delete(integration).join
    end
    private :reap_integration

    def empty?
      @integrations_in_progress.empty?
    end

    def full?
      @pool_size <= @integrations_in_progress.size
    end

    def accept_filter
      ->(request) { not busy_with?(request) }
    end

    private
    def busy_with?(request)
      @integrations_in_progress.detect do |integration, thread|
        integration.request[:workbench] == request[:workbench]
      end
    end

  end
end

