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

describe Keizoku::GitHook do

  context "without a CI tag" do
    let(:hook) { Keizoku::GitHook.new(double(IO)) }

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
    let(:hook) { Keizoku::GitHook.new(io) }

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

    let(:io) { FakeIO.new "refs/tags/ci_johndoe_workbench_sprint666" }
    let(:hook) { Keizoku::GitHook.new(io) }

    it "returns true from parse" do
      hook.parse.should eq(true)
    end

    it "provides a validation request" do
      pending "Refactoring toward new/parse/validation_request"
      hook.validation_request.should_not be_nil
    end

    it "provides no error messages"

  end

end
