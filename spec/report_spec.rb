require 'spec_helper'

class FooReport; include RubyReportable; end

describe RubyReportable::Report do

  before do
    @report = FooReport
    @report.clear
  end

  context "#_source" do
    before do
      @report.source do
        logic do
          Object.methods
        end
      end
    end

    it "should contruct a sandbox to build up source data" do
      sandbox = @report._source

      sandbox.source.should == Object.methods
    end

    it "should run available source filters on the sandbox" do
      @report.source do
        logic do
          Object.methods
        end

        filter do
          source.select {|method| method.to_s.include?('r')}
        end
      end

      @report._source.source.should == Object.methods.select {|method| method.to_s.include?('r')}
    end
  end

  context "#_data" do
    before do
      @report.source do
        logic do
          Object.methods
        end
      end
    end

    it "should be able to filter on source data" do
      @report.filter('G Methods') do
        logic do
          source.select {|element| element.to_s.include?('g')}
        end
      end

      @report._data(@report._source).should == Object.methods.select {|method| method.to_s.include?('g')}
    end

    it "should use available input when filtering data" do
      @report.filter('Filter Methods') do
        key :letter

        logic do
          source.select {|element| element.to_s.include?(input)}
        end
      end

      source_sandbox = @report._source
      options = {:input => {:letter => 'g'}}
      @report._data(source_sandbox, options).should == Object.methods.select {|method| method.to_s.include?('g')}

      source_sandbox = @report._source
      options = {:input => {:letter => 'r'}}
      @report._data(source_sandbox, options).should == Object.methods.select {|method| method.to_s.include?('r')}
    end

    it "should handle multiple filters" do
      @report.filter('G Methods') do
        logic do
          source.select {|element| element.to_s.include?('g')}
        end
      end

      @report.filter('R Methods') do
        logic do
          source.select {|element| element.to_s.include?('r')}
        end
      end

      source_sandbox = @report._source

      @report._data(source_sandbox).should == Object.methods.select {|method| method.to_s.include?('g') && method.to_s.include?('r')}
    end
  end
end
