require 'benchmark'

module RubyReportable
  module Report
    attr_accessor :data_source, :filters

    def clear
      @outputs = []
      @filters = {}
      @data_source = nil
      @report = self.to_s
      @category = 'Reports'
      @meta = {}
      @benchmarks = {}
    end

    def benchmarks
      @benchmarks ||= {}
    end

    def benchmark(name)
      benchmarks[name] ||= 0.0
      benchmarks[name] += (Benchmark.realtime { yield if block_given? } * 1000)
    end

    def meta(key, value = nil, &block)
      if block_given?
        @meta[key] = block
      else
        if value.nil?
          @meta[key]
        else
          @meta[key] = value
        end
      end
    end

    def report(string = nil)
      if string.nil?
        @report
      else
        @report = string
      end
    end

    def category(string = nil)
      if string.nil?
        @category
      else
        @category = string
      end
    end

    def source(&block)
      @data_source = RubyReportable::Source.new
      @data_source.instance_eval(&block)
    end

    def filter(name, &block)
      @filters[name] = RubyReportable::Filter.new(name)
      @filters[name].instance_eval(&block)
    end

    def finalize(&block)
      @finalize = block
    end

    def output(name, options = {}, &block)
      @outputs << RubyReportable::Output.new(name, options, block)
    end


    #
    # methods you shouldn't use inside the blocks
    #
    def outputs(hidden = false)
      if hidden
        @outputs
      else
        @outputs.select {|output| output[:hidden] != true}
      end
    end

    def useable_filters(scope)
      @filters.values.select {|filter| !filter[:input].nil? && (filter[:use].nil? || filter[:use].call(scope))}.sort_by {|filter| filter[:priority].to_i}
    end

    def _filter(filters, original_sandbox, options)
      # sort filters by priority then apply to sandbox
      filters.sort_by do |filter_name, filter|
        filter[:priority]
      end.inject(original_sandbox) do |sandbox, (filter_name, filter)|

        # find input for given filter
        sandbox[:input] = options[:input][filter[:key]] if options[:input].is_a?(Hash)

        if filter[:valid].nil? || sandbox.instance_eval(&filter[:valid])
          if filter[:logic].nil?
            sandbox
          else
            sandbox.build(:source, filter[:logic])
          end
        else
          sandbox
        end
      end
    end

    def _source(options = {})
      # build sandbox for getting the data
      RubyReportable::Sandbox.new(:meta => @meta, :source => @data_source[:logic], :inputs => options[:input] || {}, :input => nil)
    end

    def _data(sandbox, options = {})
      _filter(@filters, sandbox, options)
    end

    def _finalize(sandbox, options = {})
      if @finalize.nil?
        sandbox
      else
        sandbox[:inputs] = options[:input] || {}
        sandbox.build(:source, @finalize)
      end
    end

    def _output(source_data, options = {})
      # build sandbox for building outputs
      sandbox = RubyReportable::Sandbox.new(:meta => @meta, @data_source[:as] => nil)

      source_data.inject({:results => []}) do |rows, element|
        # fill sandbox with data element
        sandbox[@data_source[:as]] = element

        # grab outputs
        rows[:results] << @outputs.inject({}) do |row, output|
          row[output.name] = sandbox.instance_eval(&output.logic)
          row
        end

        rows
      end
    end

    def _group(group, data, options = {})
      unless group.to_s.empty?
        data[:results].inject({}) do |hash, element|
          key = element[group]
          hash[key] ||= []
          hash[key] << element
          hash
        end
      else
        data
      end
    end

    def _sort(sort, data, options = {})
      unless sort.to_s.empty?
        data.inject(Hash.new([])) do |hash, (group, elements)|
          hash[group] = elements.sort_by {|element| element[sort]}
          hash
        end
      else
        data
      end
    end

    def run(options = {})
      options = {:input => {}}.merge(options)

      # initial sandbox
      benchmark(:sandbox) do
        sandbox = _source(options)
      end

      # apply filters to source
      benchmark(:filters) do
        filtered_sandbox = _data(sandbox, options)
      end

      # finalize raw data from source
      benchmark(:finalize) do
        source_data = _finalize(filtered_sandbox, options).source
      end

      # {:default => [{outputs => values}]
      benchmark(:output) do
        data = _output(source_data, options)
      end

      # transform into {group => [outputs => values]}
      benchmark(:group) do
        grouped = _group(options[:group], data, options)
      end

      # sort grouped data
      benchmark(:sort) do
        _sort(options[:sort], grouped, options)
      end
    end # end def run

    def valid?(options = {})
      options = {:input => {}}.merge(options)
      errors = []

      # initial sandbox
      sandbox = _source(options)

      # add in inputs
      sandbox[:inputs] = options[:input]

      validity = @filters.map do |filter_name, filter|

        # find input for given filter
        sandbox[:input] = options[:input][filter[:key]] if options[:input].is_a?(Hash)

        filter_validity = filter[:valid].nil? || sandbox.instance_eval(&filter[:valid])

        if filter_validity == false
          # Ignore an empty filter unless it's required
          if !sandbox[:input].to_s.blank?
            errors << "#{filter_name} is invalid."
            false
          else
            if sandbox[:input].to_s.blank? && !filter[:require].blank?
              errors << "#{filter_name} is required."
              false
            else
              true
            end
          end
        elsif filter_validity == true
          if sandbox[:input].to_s.blank? && !filter[:require].blank?
            errors << "#{filter_name} is required."
            false
          else
            true
          end
        elsif !filter_validity.nil? && !filter_validity[:status].nil? && filter_validity[:status] == false
          # Ignore an empty filter unless it's required
          if !sandbox[:input].to_s.blank?
            errors << filter_validity[:errors]
            false
          else
            if sandbox[:input].to_s.blank? && !filter[:require].blank?
              errors << "#{filter_name} is required."
              false
            else
              true
            end
          end
        end
      end

      return {:status => !validity.include?(false), :errors => errors}

    end # end def valid?
  end
end
