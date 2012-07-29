require 'spec_helper'
require 'keizoku/git_repo'

describe Keizoku::GitRepo do

  let!(:shell_interface) { double(Class) }
  let(:repo) { Keizoku::GitRepo.new(shell_interface) }

  describe "#branch_exists?(branch_name)" do

    it "returns false if the branch does not exist" do
      shell_interface.stub(:exists?).with('refs/heads/nonexistent').and_return(false)
      repo.branch_exists?('nonexistent').should be_false
    end

    it "returns true if the branch exists" do
      shell_interface.should_receive(:exists?).with('refs/heads/existing').and_return(true)
      repo.branch_exists?('existing').should be_true
    end

  end

  def repo_has_tag(tag_refname, object, taggername="John Doe", taggeremail="<johndoe@example.com>")
    shell_interface.should_receive(:popen).with("git for-each-ref --format='%(object) %(taggername) %(taggeremail)' #{tag_refname}")
      .and_yield FakeIO.new("#{object} #{taggername} #{taggeremail}")
  end

  describe "#tag_details(tag_refname)" do

    it "returns an hash containing object and taggeremail" do
      repo_has_tag("refs/tags/tagname", "be659302b07a46ab6a4ac42a5859c3b8e293b431")
      repo.tag_details('refs/tags/tagname').should eq({
        :object => 'be659302b07a46ab6a4ac42a5859c3b8e293b431',
        :taggername => 'John Doe',
        :taggeremail => '<johndoe@example.com>',
      })
    end

  end

  def repo_has_object(object, branch)
      shell_interface.should_receive(:popen).with("git branch --contains #{object} 2>/dev/null").and_yield FakeIO.new("  #{branch}")
  end

  describe "#branch_containing(tag_refname)" do

    it "returns the name of the branch that contains the tag" do
      repo_has_tag("refs/tags/tagname", "be659302b07a46ab6a4ac42a5859c3b8e293b431")
      repo_has_object("be659302b07a46ab6a4ac42a5859c3b8e293b431", "private_branch")
      repo.branch_containing("refs/tags/tagname").should eq("private_branch")
    end

  end

end
