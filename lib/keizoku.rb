Dir.glob(File.join(File.dirname(__FILE__), "keizoku", "**", "*.rb")).each do |f|
  require f
end

module Keizoku
  VERSION = '0.0.1'
end
