module RubyReportable
  @@reports = {}

  def self.define(name, &block)
    @@reports[name] = RubyReportable::Report.new(name)
    @@reports[name].instance_eval(&block)
  end

  def [](name)
    @@reports[name]
  end

  def self.reports
    @@reports
  end
end

