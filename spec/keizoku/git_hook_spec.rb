require 'spec_helper'

require 'keizoku/git_hook'

class FakeIO

  def initialize(*lines)
    @lines = lines
  end

  def gets
    @lines.shift.chomp << "\n"
  end

end

module Keizoku
  class GitRepo
  end
end

describe Keizoku::GitHook do

  context "without a CI tag" do
    let(:io) { FakeIO.new "" }
    let(:hook) { Keizoku::GitHook.new(io) }

    it "returns false from parse" do
      hook.parse.should eq(false)
    end

    it "provides no validation request" do
      hook.parse
      hook.validation_request.should be_nil
    end

  end

  context "when it cannot identify the intended workbench branch" do

    let(:io) { FakeIO.new "refs/tags/ci_johndoe_figment" }
    let(:repo) { double(Keizoku::GitRepo, :branch_containing => "ci_johndoe_nonbench") }
    let(:hook) { Keizoku::GitHook.new(io, repo) }

    it "returns false from parse" do
      hook.parse.should eq(false)
    end

    it "provides no validation request" do
      hook.parse
      hook.validation_request.should be_nil
    end

    it "provides an error message" do
      hook.parse
      hook.errors.should be_any { |o| o.should match(/cannot identify intended workbench branch/) }
    end

  end

  context "when the intended workbench branch does not exist" do

    let(:io) { FakeIO.new "refs/tags/ci_johndoe_tag" }
    let(:repo) do
      repo = double(Keizoku::GitRepo)
      repo.stub(:branch_containing).and_return("ci_johndoe_workbench_sprint666")
      repo.stub(:branch_exists?).and_return(false)
      repo
    end
    let(:hook) { Keizoku::GitHook.new(io, repo) }

    it "returns false from parse" do
      hook.parse.should eq(false)
    end

    it "provides no validation request" do
      hook.parse
      hook.validation_request.should be_nil
    end

    it "provides an error message" do
      hook.parse
      hook.errors.should be_any { |o| o =~ /workbench_sprint666.*does not exist/ }
    end

  end

=begin
  context "when the tagger's email localpart is not in the CI tag name" do

    let(:io) { FakeIO.new "refs/tags/ci_workbench_sprint666" }
    let(:hook) { Keizoku::GitHook.new(io) }

    it "provides no validation request" do
      hook.parse
      hook.validation_request.should be_nil
    end

  end
=end

  context "when everything is awesome" do

    let(:io) { FakeIO.new "refs/tags/ci_johndoe_tag" }
    let(:repo) do
      repo = double(Keizoku::GitRepo)
      repo.stub(:branch_containing).with("refs/tags/ci_johndoe_tag").and_return("ci_johndoe_workbench_sprint666")
      repo.stub(:branch_exists?).with("workbench_sprint666").and_return(true)
      repo
    end
    let(:hook) { Keizoku::GitHook.new(io, repo) }

    it "returns true from parse" do
      hook.parse.should eq(true)
    end

    it "provides a validation request" do
      pending "Refactoring toward new/parse/validation_request"
      hook.validation_request.should_not be_nil
    end

    it "provides no error messages" do
      hook.errors.should be_empty
    end

  end

end
