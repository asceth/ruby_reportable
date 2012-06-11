module RubyReportable
  module Report
    attr_accessor :report_name, :data_source, :outputs, :filters

    def clear
      @outputs = {}
      @filters = {}
      @data_source = nil
    end

    def report(string)
      @report_name = string
      RubyReportable.add(@report_name, self)
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
        unless filter[:unless] && sandbox.instance_eval(&filter[:unless])
          sandbox.build(:source, filter[:logic])
        else
          sandbox
        end
      end
    end

    def _data(_source_sandbox, options = {})
      # add input to source sandbox
      _source_sandbox.define(:input, nil)

      @filters.inject(_source_sandbox) do |sandbox, (filter_name, filter)|
        # find input for given filter
        sandbox[:input] = options[:input][filter[:key]] if options[:input].is_a?(Hash)

        if filter[:valid].nil? || sandbox.instance_eval(&filter[:valid])
          sandbox.build(:source, filter[:logic])
        else
          sandbox
        end
      end.source
    end

    def _output(data, options = {})
      # build sandbox for building outputs
      sandbox = RubyReportable::Sandbox.new(:meta => options[:meta], @data_source[:as] => nil)

      data.inject([]) do |rows, element|
        # fill sandbox with data element
        sandbox[@data_source[:as]] = element

        # grab outputs
        rows << @outputs.inject({}) do |row, (output_name, output_logic)|
          row[output_name] = sandbox.instance_eval(&output_logic)
          row
        end
      end
    end

    def run(options = {})
      options = {:input => {}}.merge(options)

      _output(_data(_source(options), options), options)
    end # end def run
  end
end
