module RubyReportable
  class Output
    attr_accessor :name, :logic

    def initialize(name, options, block)
      @name = name
      @options = options
      @logic = block
    end

    def [](key)
      @options[key]
    end

    def []=(key, value)
      @options[key] = value
    end
  end
end
