require 'spec_helper'

describe RubyReportable::Filter do

  context "a filter" do
    before do
      @filter = RubyReportable::Filter.new('G Methods')
    end

    it "should store variables internally" do
      @filter[:logic].should == nil

      @filter.key(:g)
      @filter.logic do
        element.include?('g')
      end

      @filter[:key].should == :g
      @filter[:logic].should_not == nil
    end

    context "#require" do
      it "should automatically assume it is required when no block is given" do
        @filter.require

        @filter[:require].should == true
      end
    end
  end
end
