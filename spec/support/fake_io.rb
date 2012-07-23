class FakeIO
  def initialize(*lines)
    @lines = lines
  end

  def each_line
    until @lines.empty?
      yield gets
    end
  end

  def gets
    @lines.shift.chomp << "\n"
  end

end
