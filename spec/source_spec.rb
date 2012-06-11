require 'spec_helper'

describe RubyReportable::Source do

  context "a source" do
    before do
      @source = RubyReportable::Source.new
    end

    it "should store as and logic variables" do
      @source.as(:element)
      @source.logic do
        Object.methods.sort
      end

      @source[:as].should == :element
      @source[:logic].call.should == Object.methods.sort
    end

    it "should accumulate filters" do
      @source[:filters].size.should == 0

      @source.filter do
        element.include?('z')
      end

      @source[:filters].size.should == 1
    end
  end
end
