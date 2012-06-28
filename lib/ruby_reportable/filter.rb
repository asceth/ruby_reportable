module RubyReportable
  class Filter
    def initialize(name)
      @options = {}
      @options[:key] = name.to_s.downcase.gsub(' ', '_').gsub(/[^a-zA-Z_]+/, '')
      @options[:name] = name
      @options[:require] = false
    end

    def [](key)
      @options[key]
    end

    def []=(key, value)
      @options[key] = value
    end

    def require
      self[:require] = true
    end

    def priority(value)
      self[:priority] = value
    end

    def key(key)
      self[:key] = key
    end

    def use?(&block)
      self[:use] = block
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
