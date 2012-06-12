module RubyReportable
  class Output
    attr_accessor :name, :logic

    def initialize(name, block)
      @name = name
      @logic = block
    end
  end
end
