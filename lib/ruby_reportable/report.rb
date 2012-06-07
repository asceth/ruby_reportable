module RubyReportable
  class Report
    attr_accessor :meta, :outputs, :filters

    def initialize
      @outputs = {}
      @filters = RubyReportable::Filters.new
    end

    def source(options = {}, &block)
      @source = {:as => :source, :block => block}.merge(options)
    end

    def output(name, &block)
      @outputs[name] = block
    end

    def filter(name, options = {}, &block)
      @filters.add(name, options, &block)
    end

    def _source(options = {})
      # build sandbox for getting the data
      source_sandbox = RubyReportable::Sandbox.new(:meta => options[:meta], :source => @source[:block])

      @filters.source.inject(source_sandbox) do |sandbox, filter|
        sandbox.build(:source, filter.block)
      end
    end

    def _data(source_sandbox, options = {})
      # build sandbox for testing data against filters
      data_sandbox = RubyReportable::Sandbox.new(:meta => options[:meta], @source[:as] => nil, :input => nil)

      @filters.data.inject(source_sandbox[:source]) do |data, filter|
        # find input for given filter
        data_sandbox[:input] = options[:input][filter.key]

        if filter.valid?
          data.select do |element|
            # set sandbox up for filter
            data_sandbox[@source[:as]] = element

            data_sandbox.instance_eval(filter.logic)
          end
        else
          data
        end
      end
    end

    def _output(data, options = {})
      # build sandbox for building outputs
      output_sandbox = RubyReportable::Sandbox.new(:meta => options[:meta], @source[:as] => nil)

      data.inject([]) do |rows, element|
        # fill sandbox with data element
        output_sandbox[@source[:as]] = element

        # grab outputs
        rows << @outputs.inject({}) do |row, output_name, output_logic|
          row[output_name] = output_sandbox.instance_eval(&output_logic)
        end
      end
    end

    def run(options = {})
      options = {:input => {}}.merge(options)

      _output(_data(_source(options), options), options)
    end # end run
  end
end
