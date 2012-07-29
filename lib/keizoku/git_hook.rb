require 'ostruct'

module Keizoku

  class GitHook

    #TODO Move repo to last arg so it can be defaulted to GitRepo.new
    def initialize(io, repo, repo_url)
      @io = io
      @repo = repo
      @repo_url = repo_url
      @errors = []
    end

    def parse
      @io.each_line { |line| parse_ci_tag line }
      handle_ci_tag if @tag
    end

    def integration_request
      @integration_request
    end

    def errors
      @errors
    end

    private

    def parse_ci_tag(line)
      if line =~ %r{\b(refs/tags/ci_.+)}
        if @tag
          @errors << "multiple CI tags not supported in a single push"
        else
          @tag = $1
        end
      end
    end

    def handle_ci_tag
      set_tag_details
      set_workbench_branch
      validate
      build_integration_request if valid?
    end

    def set_tag_details
      details = @repo.tag_details(@tag)
      @taggeremail = details[:taggeremail]
      @taggername = details[:taggername]
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
      localpart = @taggeremail.gsub(/<(.+)@.+>$/, '\1')
      @tag =~ %r{refs/tags/ci_#{localpart}_}
    end

    def workbench_branch_exists?
      @repo.branch_exists?(@workbench)
    end

    def valid?
      @errors.empty?
    end

    def build_integration_request
      @integration_request = {
        :workbench => @workbench,
        :taggeremail => @taggeremail,
        :taggername => @taggername,
        :commit => @commit,
        :tag => @tag,
        :repo_url => @repo_url
      }
    end

  end

end
