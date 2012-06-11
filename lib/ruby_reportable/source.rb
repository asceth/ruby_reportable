module RubyReportable
  class Source
    def initialize
      @options = {:filters => [], :as => :element}
    end

    def [](key)
      @options[key]
    end

    def []=(key, value)
      @options[key] = value
    end

    def as(variable_name)
      self[:as] = variable_name
    end

    def logic(&block)
      self[:logic] = block
    end

    def filter(options = {}, &block)
      self[:filters] << options.merge(:logic => block)
    end
  end
end
