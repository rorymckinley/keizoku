Dir.glob(File.join("keizoku", "**", "*.rb")).each do |f|
  require f
end
