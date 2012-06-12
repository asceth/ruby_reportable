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
  end
end
