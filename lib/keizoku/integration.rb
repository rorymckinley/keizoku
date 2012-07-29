module Keizoku
  class Integration
    attr_reader :request

    def self.build(request, validator_path="keizoku-validate-rake-spec")
      new(request, validator_path)
    end

    def initialize(request, validator_path)
      @request = request
      @validator_path = validator_path
    end
    private :initialize

    def integrate
      @successful = system(environment, "keizoku-integrate")
      @completed = true
      raise RuntimeError.new("Could not execute keizoku-integrate") if @successful.nil?
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
        memo[key.to_s.upcase] = value
        memo
      end
    end
    private :request_environment

    def completed?
      @completed
    end

    def successful?
      @successful
    end

  end
end


