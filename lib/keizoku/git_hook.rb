module Keizoku

  class GitHook

    def initialize(io, repo = nil)
      @io = io
      @repo = repo
      @errors = []
    end

    def parse
      return false unless @io.gets =~ %r{\b(refs/tags/ci_.+)}
      @tag = $1

      set_tag_details
      set_workbench_branch
      validate
      @errors.empty?
    end

    def validation_request
    end

    def errors
      @errors
    end

    private

    def set_tag_details
      details = @repo.tag_details(@tag)
      @taggeremail = details[:taggeremail]
    end
    
    def set_workbench_branch
      set_tag_branch
      @tag_branch =~ %r{ci_.+_(workbench_.+)}
      @workbench = $1
    end

    def set_tag_branch
      @tag_branch = @repo.branch_containing(@tag)
    end

    def validate
      if !tag_belongs_to_tagger
        @errors << "localpart from '#{@taggeremail}' not in tag name"
      elsif !@tag_branch
        @errors << "no branch contains tag '#{@tag}'"
      elsif !@workbench
        @errors << "cannot identify intended workbench branch"
      elsif !@repo.branch_exists?(@workbench)
        @errors << "branch '#{@workbench}' does not exist"
      end
    end

    def tag_belongs_to_tagger
      localpart = @taggeremail.gsub(/@.+$/, '')
      @tag =~ %r{refs/tags/ci_#{localpart}_}
    end

  end

end

