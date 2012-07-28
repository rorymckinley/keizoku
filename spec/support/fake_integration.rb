require 'io/wait'

class FakeIntegration

  def self.build(request)
    new(request)
  end

  attr_accessor :request

  def initialize(request)
    @request = request
  end

  def integrate
    @asked_to_integrate = true
    until @completed
      Thread.pass
    end
  end

  def has_been_asked_to_integrate?
    @asked_to_integrate
  end

  def complete
    @completed = true
  end

  def completed?
    @completed
  end
end
