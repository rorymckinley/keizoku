class FakeIntegration

  def self.build(request)
    reader, writer = IO.pipe
    new(request, reader, writer)
  end

  attr_accessor :request

  def initialize(request, reader, writer)
    @request, @reader, @writer = request, reader, writer
  end

  def integrate(request)
    @reader.gets
  end

  def fake_complete
    @writer.puts
    sleep 0.1
  end
end

=begin
  describe "fake integration" do
    it "works" do
      integration = FakeIntegration.build({:some => :junk})
      Process.fork { integration.integrate(nil) }
      Process.wait(-1, Process::WNOHANG).should be_nil
      integration.fake_complete
      Process.wait(-1, Process::WNOHANG).should_not be_nil
    end
  end
=end
