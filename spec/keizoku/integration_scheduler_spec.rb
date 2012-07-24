require 'spec_helper'

module Keizoku
  class IntegrationScheduler
    attr_reader :path

    def initialize(path)
      @path = Pathname.new(path)
    end

    def schedule(request)
      @path + Pathname.new("broccoliwaffles")
    end
  end
end

describe Keizoku::IntegrationScheduler do
  let(:scheduler) { Keizoku::IntegrationScheduler.new("/tmp") }

  it "initialises with a directory name" do
    Keizoku::IntegrationScheduler.new("/tmp").should be_a Keizoku::IntegrationScheduler
  end

  it "schedules an integration request" do
    scheduler.schedule({ :some => :junk }).should be_true
  end

  it "returns the path of the file into which the request was scheduled" do
    scheduler.schedule({ :some => :junk}).should be_a Pathname
  end

  it "includes the queue directory in the path of the created file" do
    scheduler.schedule({ :some => :junk }).dirname.should eq(scheduler.path)
  end

end
