module Keizoku

  class GitHook

    def initialize(io, repo = nil)
      @io = io
      @repo = repo
      @errors = []
    end

    def parse
      unless @io.gets =~ %r{\b(refs/tags/ci_.+)}
        return false
      end

      @tag = $1
      set_workbench_branch
      workbench_branch_exists?
    end

    def validation_request
    end

    def errors
      @errors
    end

    def set_workbench_branch
      @tag_branch = @repo.branch_containing @tag
      if @tag_branch =~ %r{ci_.+_(workbench_.+)}
        @workbench = $1
      else
        @errors << "cannot identify intended workbench branch"
        false
      end
    end

    def workbench_branch_exists?
      if !@workbench
        @errors << "cannot identify intended workbench branch"
        false
      elsif !@repo.branch_exists?(@workbench)
        @errors << "branch '#{@workbench}' does not exist"
        false
      else
        true
      end
    end

  end

end

