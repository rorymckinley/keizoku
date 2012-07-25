require 'spec_helper'
require 'keizoku/git_hook'

module Keizoku
  class GitRepo
  end
end

describe Keizoku::GitHook do

  let(:tag_details) { { :taggeremail => 'johndoe@example.com', :object => "de661a9d" } }
  let(:repo) do
    repo = double(Keizoku::GitRepo)
    repo.stub(:tag_details).and_return(tag_details)
    repo.stub(:branch_containing).and_return("ci_johndoe_workbench_sprint666")
    repo.stub(:branch_exists?).and_return(true)
    repo
  end

  context "without a CI tag" do

    let(:io) { FakeIO.new "" }
    let(:hook) { Keizoku::GitHook.new(io) }

    it "returns false from parse" do
      hook.parse.should be_false
    end

    it "provides no integration request" do
      hook.parse
      hook.integration_request.should be_nil
    end

    it "provides no error messages" do
      hook.parse
      hook.errors.should be_empty
    end

  end

  context "when the tag is not associated with a branch" do

    let(:io) { FakeIO.new "refs/tags/ci_johndoe_no_branch_pushed" }
    let(:hook) { Keizoku::GitHook.new(io, repo) }

    before(:each) { repo.stub(:branch_containing).and_return(nil) }

    it "returns false from parse" do
      hook.parse.should be_false
    end

    it "provides no integration request" do
      hook.parse
      hook.integration_request.should be_nil
    end

    it "provides an error message" do
      hook.parse
      hook.errors.should be_any { |o| o.should match(%r{no branch contains.*refs/tags/ci_johndoe_no_branch_pushed}) }
    end

  end

  context "when it cannot identify the intended workbench branch" do

    let(:io) { FakeIO.new "refs/tags/ci_johndoe_figment" }
    let(:hook) { Keizoku::GitHook.new(io, repo) }
    before(:each) { repo.stub(:branch_containing).and_return("ci_johndoe_nonbench") }

    it "returns false from parse" do
      hook.parse.should be_false
    end

    it "provides no integration request" do
      hook.parse
      hook.integration_request.should be_nil
    end

    it "provides an error message" do
      hook.parse
      hook.errors.should be_any { |o| o.should match(/cannot identify intended workbench branch/) }
    end

  end

  context "when the intended workbench branch does not exist" do

    let(:io) { FakeIO.new "refs/tags/ci_johndoe_tag" }
    let(:hook) { Keizoku::GitHook.new(io, repo) }
    before(:each) { repo.stub(:branch_exists?).and_return(false) }

    it "returns false from parse" do
      hook.parse.should be_false
    end

    it "provides no integration request" do
      hook.parse
      hook.integration_request.should be_nil
    end

    it "provides an error message" do
      hook.parse
      hook.errors.should be_any { |o| o =~ /workbench_sprint666.*does not exist/ }
    end

  end

  context "when the tagger's email localpart is not in the CI tag name" do

    let(:io) { FakeIO.new "refs/tags/ci_tag" }
    let(:hook) { Keizoku::GitHook.new(io, repo) }

    it "returns false from parse" do
      hook.parse.should be_false
    end

    it "provides no integration request" do
      hook.parse
      hook.integration_request.should be_nil
    end

    it "provides an error message" do
      hook.parse
      hook.errors.should be_any { |o| o =~ /johndoe.*not in tag name/ }
    end

  end

  context "when everything is awesome" do

    let(:io) { FakeIO.new "refs/heads/ci_johndoe_workbench_sprint666", "refs/tags/ci_johndoe_tag" }
    let(:repo) do
      repo = double(Keizoku::GitRepo)
      repo.should_receive(:tag_details).with("refs/tags/ci_johndoe_tag").and_return(tag_details)
      repo.should_receive(:branch_containing).with("refs/tags/ci_johndoe_tag").and_return("ci_johndoe_workbench_sprint666")
      repo.should_receive(:branch_exists?).with("workbench_sprint666").and_return(true)
      repo
    end
    let(:hook) { Keizoku::GitHook.new(io, repo) }

    it "returns true from parse" do
      hook.parse.should be_true
    end

    it "provides a integration request" do
      hook.parse

      integration_request = hook.integration_request
      integration_request[:workbench].should eq("workbench_sprint666")
      integration_request[:taggeremail].should eq("johndoe@example.com")
      integration_request[:commit].should eq("de661a9d")
    end

    it "provides no error messages" do
      hook.parse
      hook.errors.should be_empty
    end

  end

  context "when multiple CI tags are received" do

    let(:io) { FakeIO.new(
      "refs/heads/ci_johndoe_workbench_sprint666", "refs/tags/ci_johndoe_tag", "refs/tags/ci_johndoe_testing"
    ) }
    let(:hook) { Keizoku::GitHook.new(io, repo) }

    it "returns false from parse" do
      hook.parse.should be_false
    end

    it "provides no integration request" do
      hook.parse
      hook.integration_request.should be_nil
    end

    it "provides an error message" do
      hook.parse
      hook.errors.should be_any { |o| o =~ /multiple CI tags/ }
    end

  end

end
