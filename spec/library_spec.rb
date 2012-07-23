require 'spec_helper'
require 'keizoku'

describe "keizoku library loader" do

  it "loads Keizoku::GitHook" do
    Keizoku::GitHook.should be_a(Class)
  end

  it "loads Keizoku::GitRepo" do
    Keizoku::GitRepo.should be_a(Class)
  end

end
