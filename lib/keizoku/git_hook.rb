module Keizoku

  class GitHook

    def initialize(io, repo = nil)
      @io = io
      @repo = repo
    end

    def parse
      unless @io.gets =~ %r{\b(refs/tags/ci_.+)}
        return false
      end

      tag = $1
      branch = @repo.branch_containing tag
      branch =~ %r{ci_.+_workbench_.+} ? true : false
    end

    def validation_request
    end

    def errors
      [ "cannot identify intended workbench branch" ]
    end

  end

end

