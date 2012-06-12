module RubyReportable
  @@reports = {}

  def self.included(base)
    base.send :extend, RubyReportable::Report
    base.clear

    @@reports[base.to_s] = base
  end

  def self.reports
    @@reports
  end
end

