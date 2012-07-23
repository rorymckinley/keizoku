require 'spec_helper'

class FakeIO

  def initialize(*lines)
    @lines = lines
  end

  def gets
    @lines.shift.chomp << "\n"
  end

  def each_line
    @lines.each { |l| yield l }
  end
end

module Keizoku

  class GitRepo

    def initialize(path, shell_interface = File)
      @path = path
      @shell_interface = shell_interface
    end

    def branch_exists?(branch_name)
      @shell_interface.exists?("#{@path}/refs/heads/#{branch_name}")
    end

    def tag_details(tag_refname)
      object = email_spec = nil
      @shell_interface.popen(*%W{git for-each-ref --format="%(object)\ %(taggeremail)" refs/tags/name}) do |io|
        object, email_spec = io.gets.chomp.split
        email_spec.gsub!(/[<>]/, '')
      end
      { :object => object, :taggeremail => email_spec }
    end

  end

end

describe Keizoku::GitRepo do

  let(:shell_interface) { double(Class) }
  let(:repo) { Keizoku::GitRepo.new('/path/to/repo', shell_interface) }

  describe "#branch_exists?(branch_name)" do

    it "returns false if the branch does not exist" do
      shell_interface.stub(:exists?).with('/path/to/repo/refs/heads/nonexistent').and_return(false)
      repo.branch_exists?('nonexistent').should be_false
    end

    it "returns true if the branch exists" do
      shell_interface.should_receive(:exists?).with('/path/to/repo/refs/heads/existing').and_return(true)
      repo.branch_exists?('existing').should be_true
    end

  end

  describe "#tag_details(tag_refname)" do

    it "returns an hash containing object and taggeremail" do
      shell_interface.should_receive(:popen).with(*%W{git for-each-ref --format="%(object)\ %(taggeremail)" refs/tags/name}).
        and_yield FakeIO.new("be659302b07a46ab6a4ac42a5859c3b8e293b431 <sheldonh@starjuice.net>\n")
      repo.tag_details('refs/tags/name').should eq({
        :object => 'be659302b07a46ab6a4ac42a5859c3b8e293b431',
        :taggeremail => 'sheldonh@starjuice.net',
      })
    end

  end

end

