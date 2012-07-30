require 'keizoku/sub_process'

module Keizoku
  class Integration
    attr_reader :log, :request

    def self.build(request, validator_path="keizoku-validate-rake-spec", integration_helper = "keizoku-integrate")
      new(request, validator_path, integration_helper)
    end

    def initialize(request, validator_path, integration_helper)
      @request = request
      @validator_path = validator_path
      @integration_helper = integration_helper
    end
    private :initialize

    def integrate
      @process = Keizoku::SubProcess.new(environment, @integration_helper)
      @process.execute
      harvest_process_outcome
    end

    def environment
      integration_environment.merge(request_environment)
    end
    private :environment

    def integration_environment
      {"VALIDATOR" => @validator_path}
    end
    private :integration_environment

    def request_environment
      @request.inject({}) do |memo,(key,value)|
        memo[key.to_s.upcase] = value.to_s
        memo
      end
    end
    private :request_environment

    def harvest_process_outcome
      @log = @process.log
      @successful = @process.successful?
      @completed = true
    end
    private :harvest_process_outcome

    def completed?
      @completed
    end

    def successful?
      @successful
    end

  end
end


