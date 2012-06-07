module RubyReportable
  class Report
    attr_accessor :meta, :outputs, :filters

    def initialize
      @outputs = {}
      @source_filters = {}
      @data_filters = {}
    end

    def source(options = {}, &block)
      @source = options.merge(:block => block)
    end

    def output(name, &block)
      @outputs[name] = block
    end

    def filter(name, options = {}, &block)
      @filters[name] = RubyReportable::Filter.new(options, &block)
    end

    def run(options)
      options = {:input => {}}.merge(options)
      @meta = options.delete(:meta) || {}

      @sandbox = RubyReportable::Sandbox.new(@meta, @source[:block].call)
      @sandbox = @filters.select(&:source?).inject(@sandbox) do |sandbox, filter|
        sandbox.build(filter.block)
      end

      # TODO change this to map by filter first
      # filters.inject(source) { source.select(filter.met?) if filter.valid? }
      data = @sandbox.source.select do |row|
        filters.data.map do |filter|
          input = options[:input][filter.key]
          if filter.valid?(input)
            row.instance_eval(filter.operand) == input
          else
            nil
          end
        end.compact.include?(true)
      end # end source select
    end # end run
  end
end
