module Keizoku

  class GitRepo

    def initialize(shell_interface = File)
      @shell_interface = shell_interface
    end

    def branch_exists?(branch_name)
      @shell_interface.exists?("refs/heads/#{branch_name}")
    end

    def tag_details(tag_refname)
      @shell_interface.popen("git for-each-ref --format='%(object) %(taggeremail)' #{tag_refname}") do |io|
        object, bracketed_email = io.gets.chomp.split
        email = bracketed_email.gsub(/[<>]/, '')
        { :object => object, :taggeremail => email }
      end
    end

    def branch_containing(tag_refname)
      object = tag_details(tag_refname)[:object]
      @shell_interface.popen("git branch --contains #{object} 2>/dev/null") do |io|
        io.gets.strip
      end
    end

  end

end
