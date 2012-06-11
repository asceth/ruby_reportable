module RubyReportable
  @@reports = {}

  def self.included(base)
    base.class_eval do
      @outputs = {}
      @filters = {}
    end

    base.send :extend, RubyReportable::Report
  end

  def self.add(name, klass)
    @@reports[name] = klass
  end

  def [](name)
    @@reports[name]
  end

  def self.reports
    @@reports
  end
end

