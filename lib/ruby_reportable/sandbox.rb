module RubyReportable
  class Sandbox
    def initialize(methods)
      @values = {}

      methods.map do |key, value|
        define(key, value)
      end
    end

    def build(base, block)
      @values[base] = instance_eval(&block)
      self
    end

    def [](key)
      @values[key]
    end

    def []=(key, value)
      if value.is_a?(Proc)
        @values[key] = value.call
      else
        @values[key] = value
      end
    end

    def define(key, value)
      self.class.class_eval do
        define_method(key) do
          if value.is_a?(Proc)
            @values[key] ||= value.call
          else
            @values[key] ||= value
          end
        end
      end
    end
  end
end
