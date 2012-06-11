require 'spec_helper'

describe RubyReportable::Sandbox do

  context "a sandbox" do
    before do
      @sandbox = RubyReportable::Sandbox.new(:source => [1, 2])
    end

    it "should create new methods based on options" do
      RubyReportable::Sandbox.new.respond_to?(:source).should == false
      @sandbox.respond_to?(:source).should == true
    end

    it "should store the value of a defined call" do
      @sandbox.source.should == [1, 2]
      @sandbox[:source].should == [1, 2]
    end

    it "should not call a method when trying to retrieve the stored value directly" do
      @sandbox[:source].should == nil
    end

    it "should be able to define a new method with value dynamically" do
      @sandbox.define(:arbitrary, proc { Time.now })
      @sandbox.respond_to?(:arbitrary).should == true
    end

    it "should not override a stored value with a method call" do
      @sandbox[:source] = [3, 4]
      @sandbox.source.should == [3, 4]
    end

    it "should allow you to build up a stored value" do
      @sandbox[:source] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
      @sandbox.build(:source, proc { source.select(&:odd?) })

      @sandbox[:source].should == [1, 3, 5, 7, 9]
    end
  end
end
