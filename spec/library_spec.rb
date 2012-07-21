require 'spec_helper'

require 'keizoku'

describe "keizoku library loader" do

  it "loads Keizoku::GitHook" do
    Keizoku::GitHook.should be_a(Class)
  end

end

