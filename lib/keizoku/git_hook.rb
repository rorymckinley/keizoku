require 'ostruct'

module Keizoku

  class GitHook

    def initialize(io, repo = nil)
      @io = io
      @repo = repo
      @errors = []
    end

    def parse
      if @io.gets =~ %r{\b(refs/tags/ci_.+)}
        @tag = $1
        handle_ci_tag
      end
    end

    def integration_request
      @integration_request
    end

    def errors
      @errors
    end

    private

    def handle_ci_tag
      set_tag_details
      set_workbench_branch
      validate
      build_integration_request if valid?
    end

    def set_tag_details
      details = @repo.tag_details(@tag)
      @taggeremail = details[:taggeremail]
      @commit = details[:object]
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
      if !tag_belongs_to_tagger?
        @errors << "localpart from '#{@taggeremail}' not in tag name"
      elsif !@tag_branch
        @errors << "no branch contains tag '#{@tag}'"
      elsif !@workbench
        @errors << "cannot identify intended workbench branch"
      elsif !workbench_branch_exists?
        @errors << "branch '#{@workbench}' does not exist"
      end
    end

    def tag_belongs_to_tagger?
      localpart = @taggeremail.gsub(/@.+$/, '')
      @tag =~ %r{refs/tags/ci_#{localpart}_}
    end

    def workbench_branch_exists?
      @repo.branch_exists?(@workbench)
    end

    def valid?
      @errors.empty?
    end

    def build_integration_request
      @integration_request = OpenStruct.new({
        :workbench => @workbench,
        :taggeremail => @taggeremail,
        :commit => @commit,
      })
    end

  end

end
