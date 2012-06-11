module RubyReportable
  class Sandbox
    def metaclass
      class << self; self; end
    end
    def initialize(_methods = {})
      @values = {}

      _methods.map do |key, value|
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
      if self.class.respond_to?(:define_singleton_method)
        define_singleton_method(key) do
          if value.is_a?(Proc)
            @values[key] ||= value.call
          else
            @values[key] ||= value
          end
        end
      else
        metaclass.send(:define_method, key, Proc.new do
                         if value.is_a?(Proc)
                           @values[key] ||= value.call
                         else
                           @values[key] ||= value
                         end
                       end)
      end
    end
  end
end
