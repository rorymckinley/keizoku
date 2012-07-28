module Keizoku
  class IntegrationDispatcher

    def initialize(pool_size, integration_factory = ->(r) { Keizoku::Integration.build(r) })
      @integration_factory = integration_factory
      @pool_size = pool_size
      @integrations_in_progress = {}
    end

    def start_integrating(request)
      integration = @integration_factory.call(request)
      pid = Process.fork { integration.integrate }
      @integrations_in_progress[pid] = integration
    end

    def completed_integrations
      completed_integrations = []
      while !empty? and pid = Process.wait(-1, Process::WNOHANG)
        completed_integrations << @integrations_in_progress.delete(pid)
      end
      completed_integrations
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
      @integrations_in_progress.detect { |pid, integration| integration.request == request }
    end

  end
end

