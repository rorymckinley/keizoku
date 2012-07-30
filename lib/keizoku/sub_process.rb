require 'io/wait'

module Keizoku

  class SubProcess

    def initialize(environment, command)
      @environment = environment
      @command = command
    end

    def execute
      open_ipc_pipes
      @child_pid = fork do
        child_process_handler
      end
      parent_process_handler
    end

    def log
      @log
    end

    def successful?
      @successful
    end

    def completed?
      @completed
    end

    private

    def open_ipc_pipes
      @log_r, @log_w = IO.pipe
      @exit_r, @exit_w = IO.pipe
    end

    def child_process_handler
      close_ipc_readers
      execute_child_process
      close_ipc_writers
    end

    def execute_child_process
      ENV.replace(process_environment)
      @log_w.write `#{@command} 2>&1`
      @exit_w.puts $?.to_i
    end

    def parent_process_handler
      close_ipc_writers
      harvest_child_process_outcome
      close_ipc_readers
    end

    def close_ipc_readers
      @log_r.close
      @exit_r.close
    end

    def close_ipc_writers
      @log_w.close
      @exit_w.close
    end

    def harvest_child_process_outcome
      @log = ''
      until Process.wait(@child_pid, Process::WNOHANG)
        read_child_success if @exit_r.ready?
        read_child_log if @log_r.ready?
        sleep 0.001
      end
      read_child_success unless @exit_r.eof?
      read_child_log unless @log_r.eof?
    end

    def read_child_success
      @successful = @exit_r.gets.chomp == '0'
    end

    def read_child_log
      @log += @log_r.read
    end

    def process_environment
      ENV.to_hash.merge(@environment)
    end

  end

end
