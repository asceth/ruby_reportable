require 'benchmark'

module RubyReportable
  module Report
    attr_accessor :data_source, :filters, :records_returned

    def clear
      @outputs = []
      @filters = {}
      @data_source = nil
      @report = self.to_s
      @category = 'Reports'
      @allow_group = true
      @allow_sort = true
      @meta = {}
      @benchmarks = {}
      @records_returned = 0
    end

    # :sandbox, :filters, :finalize, :output, :group, :sort
    def benchmarks
      @benchmarks ||= {}
    end

    def benchmark(name)
      benchmarks[name] ||= 0.0

      @result = nil

      time = Benchmark.realtime do
        @result = yield
      end

      benchmarks[name] += time
      @result
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

    def allow_group(string = nil)
      if string.nil?
        @allow_group
      else
        @allow_group = string
      end
    end

    def allow_sort(string = nil)
      if string.nil?
        @allow_sort
      else
        @allow_sort = string
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

      source_data.inject([]) do |rows, element|
        # fill sandbox with data element
        sandbox[@data_source[:as]] = element

        # grab outputs
        rows << @outputs.inject({}) do |row, output|
          row[output.name] = sandbox.instance_eval(&output.logic)
          row
        end

        rows
      end
    end

    def _sort(sort, data, options = {})
      if sort.to_s.empty?
        data
      else
        sort = [sort] unless sort.is_a?(Array)

        data.sort_by {|element| sort.map {|column| element[column]} }
      end
    end

    def _group(group, data, options = {})
      # Run through elements in data which are ordered
      # from the previous call to #_sort via #run
      #
      # Since the elements are already sorted, as we pop
      # them into their grouping they will remain sorted as
      # intended
      #
      if group.to_s.empty?
        {:results => data}
      else
        group = [group] unless group.is_a?(Array)
        group.map!(&:to_s)

        # the last group critieria should contain an array
        # so lets pop it off for special use
        last_group = group.pop

        data.inject({}) do |hash, element|
          # grab a local reference to the hash
          ref = hash

          # run through initial groupings to grab local ref
          # and default them to {}
          group.map do |grouping|
            key = element[grouping]
            ref[key] ||= {}
            ref = ref[key]
          end

          # handle our last grouping
          key = element[last_group]
          ref[key] ||= []
          ref[key] << element

          hash
        end
      end
    end

    def run(options = {})
      options = {:input => {}}.merge(options)

      # initial sandbox
      sandbox = benchmark(:sandbox) do
        _source(options)
      end

      # apply filters to source
      filtered_sandbox = benchmark(:filters) do
        _data(sandbox, options)
      end

      # finalize raw data from source
      source_data = benchmark(:finalize) do
        _finalize(filtered_sandbox, options).source
      end

      # {:default => [{outputs => values}]
      data = benchmark(:output) do
        _output(source_data, options)
      end

      # now that we have all of our data go ahead and cache the size
      records_returned = data.size

      # sort the data first cause that makes sense you know
      sorted = benchmark(:sort) do
        _sort(options[:sort], data, options)
      end

      # transform into {group => {group => [outputs => values]}}
      # level of grouping depends on how many groups are passed in
      benchmark(:group) do
        _group(options[:group], sorted, options)
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
