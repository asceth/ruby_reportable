module RubyReportable
  class Filter
    def initialize(name)
      @options = {}
      self[:key] = name.to_s.downcase
      self[:name] = name
    end

    def [](key)
      @options[key]
    end

    def []=(key, value)
      @options[key] = value
    end

    def require(&block)
      if block_given?
        self[:require] = block
      else
        self[:require] = true
      end
    end

    def key(key)
      self[:key] = key
    end

    def input(type, &block)
      self[:input] = type
      self[:collection] = block
    end

    def valid?(&block)
      self[:valid] = block
    end

    def logic(&block)
      self[:logic] = block
    end
  end
end
