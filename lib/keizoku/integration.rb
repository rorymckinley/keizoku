require 'io/wait'

module Keizoku
  class Integration
    attr_reader :request

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
      log_r, log_w = IO.pipe
      exit_r, exit_w = IO.pipe
      pid = fork do
        log_r.close
        exit_r.close
        ENV.replace(environment)
        if File.executable?(@integration_helper)
          log = `#{@integration_helper} 2>&1`
          exit_w.puts $?.to_i
          log_w.write log
        end
        exit_w.close
        log_w.close
      end
      log_w.close
      exit_w.close
      @log = ''
      while Process.wait(pid, Process::WNOHANG)
        @successful = exit_r.gets.chomp == '0' if exit_r.ready?
        @log += log_r.read if log_r.ready?
        sleep 0.001
      end
      unless exit_r.eof?
        @successful = exit_r.gets.chomp == '0'
      end
      @log += log_r.read unless log_r.eof?
      exit_r.close
      log_r.close
      #@successful = system(environment, @integration_helper)
      @completed = true
      raise RuntimeError.new("Could not execute #{@integration_helper}") if @successful.nil?
    end

    def log
      @log
    end

    def environment
      merge process_environment, integration_environment, request_environment
    end
    private :environment

    def merge(*args)
      args.inject({}) { |m, environment| m.merge! environment }
    end
    private :merge

    def process_environment
      ENV.to_hash
    end
    private :process_environment

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

    def completed?
      @completed
    end

    def successful?
      @successful
    end

  end
end


