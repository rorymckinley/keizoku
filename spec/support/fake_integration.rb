require 'io/wait'

class FakeIntegration

  def self.build(request)
    complete_r, complete_w = IO.pipe
    callback_r, callback_w = IO.pipe
    new(request, complete_r, complete_w, callback_r, callback_w)
  end

  attr_accessor :request

  def initialize(request, complete_r, complete_w, callback_r, callback_w)
    @request = request
    @complete_r, @complete_w = complete_r, complete_w
    @callback_r, @callback_w = callback_r, callback_w
  end

  def integrate
    @complete_r.gets
    @callback_w.puts
    pidlog "integrate called"
  end

  def has_been_asked_to_integrate?
    @integrate_called ||= if @callback_r.ready?
      @callback_r.gets
      pidlog "has_been_asked_to_integrate? => true"
      true
    else
      pidlog "has_been_asked_to_integrate? => false"
      false
    end
  end

  def complete
    @complete_w.puts
    pidlog "complete called"
    sleep 0.025
  end

  def pidlog(message)
    #$stderr.puts "[#{Process.pid}] #{message}"
  end
end
