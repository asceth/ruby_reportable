module RubyReportable
  class Report
    attr_accessor :name, :data_source, :meta, :outputs, :filters

    def initialize(name)
      @name = name
      @outputs = {}
      @filters = {}
    end

    def source(&block)
      @data_source = RubyReportable::Source.new
      @data_source.instance_eval(&block)
    end

    def output(name, &block)
      @outputs[name] = block
    end

    def filter(name, &block)
      @filters[name] = RubyReportable::Filter.new(name)
      @filters[name].instance_eval(&block)
    end

    def _source(options = {})
      # build sandbox for getting the data
      source_sandbox = RubyReportable::Sandbox.new(:meta => options[:meta], :source => @data_source[:logic])

      @data_source[:filters].inject(source_sandbox) do |sandbox, filter|
        unless sandbox.instance_eval(&filter[:unless])
          sandbox.build(:source, filter[:logic])
        else
          sandbox
        end
      end
    end

    def _data(source_sandbox, options = {})
      # build sandbox for testing data against filters
      data_sandbox = RubyReportable::Sandbox.new(:meta => options[:meta], @data_source[:as] => nil, :input => nil)

      @filters.inject(source_sandbox[:source]) do |data, filter|
        # find input for given filter
        data_sandbox[:input] = options[:input][filter.key]

        if filter.valid?
          data.select do |element|
            # set sandbox up for filter
            data_sandbox[@data_source[:as]] = element

            data_sandbox.instance_eval(filter.logic)
          end
        else
          data
        end
      end
    end

    def _output(data, options = {})
      # build sandbox for building outputs
      output_sandbox = RubyReportable::Sandbox.new(:meta => options[:meta], @data_source[:as] => nil)

      data.inject([]) do |rows, element|
        # fill sandbox with data element
        output_sandbox[@data_source[:as]] = element

        # grab outputs
        rows << @outputs.inject({}) do |row, output_name, output_logic|
          row[output_name] = output_sandbox.instance_eval(&output_logic)
        end
      end
    end

    def run(options = {})
      options = {:input => {}}.merge(options)

      _output(_data(_source(options), options), options)
    end # end def run
  end
end
