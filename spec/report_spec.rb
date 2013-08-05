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

      @report._data(@report._source).source.should == Object.methods.select {|method| method.to_s.include?('g')}
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
      @report._data(source_sandbox, options).source.should == Object.methods.select {|method| method.to_s.include?('g')}

      source_sandbox = @report._source
      options = {:input => {:letter => 'r'}}
      @report._data(source_sandbox, options).source.should == Object.methods.select {|method| method.to_s.include?('r')}
    end

    it "should handle multiple filters" do
      @report.filter('G Methods') do
        priority 0

        logic do
          source.select {|element| element.to_s.include?('g')}
        end
      end

      @report.filter('R Methods') do
        priority 1

        logic do
          source.select {|element| element.to_s.include?('r')}
        end
      end

      source_sandbox = @report._source

      @report._data(source_sandbox).source.should == Object.methods.select {|method| method.to_s.include?('g') && method.to_s.include?('r')}
    end

    it "should handle multiple filters in the right priority" do
      @report.source do
        logic do
          Object.methods
        end
      end

      @report.filter('G Methods') do
        priority 0

        logic do
          source.map(&:to_s).select {|element| element.include?('g')}
        end
      end

      @report.filter('R Methods') do
        priority 1

        logic do
          source.select {|element| element.include?('r')}.map(&:to_sym)
        end
      end

      source_sandbox = @report._source

      # G Methods has to run first because otherwise Object.methods
      # returns symbols and R Methods is trying to do a include? on a symbol
      @report._data(source_sandbox).source.should == Object.methods.select {|method| method.to_s.include?('g') && method.to_s.include?('r')}
    end
  end

  context "#_group" do
    it "should group results" do
      @report.source do
        logic do
          [:method]
        end
      end

      @report.output('name') do
        element
      end

      @report.output('letter') do
        element.to_s[0]
      end

      source_data = @report._data(@report._source).source

      @report._group('letter', @report._output(source_data)).should == {"m" => [{'name' => :method, 'letter' => 'm'}]}
    end

    it "should handle multiple groupings" do

      raw = []
      raw[0] = ['test1', 29201, 'road']
      raw[1] = ['test2', 29201, 'road']
      raw[2] = ['test3', 29201, 'drive']
      raw[3] = ['test4', 29204, 'road']

      output = []
      [0, 1, 2, 3].map do |index|
        output[index] = {
          'name' => raw[index][0],
          'zip' => raw[index][1],
          'path' => raw[index][2]
        }
      end

      result = {
        29201 => {
          'road' => [output[0], output[1]],
          'drive' => [output[2]]
        },
        29204 => {
          'road' => [output[3]]
        }
      }

      @report.source do
        logic do
          [
           raw[0],
           raw[1],
           raw[2],
           raw[3]
          ]
        end
      end

      @report.output('name') do
        element[0]
      end

      @report.output('zip') do
        element[1]
      end

      @report.output('path') do
        element[2]
      end

      source_data = @report._data(@report._source).source

      @report._group(['zip', 'path'], @report._output(source_data)).should == result
    end
  end

  context "#_sort" do
    it "should sort results" do
      @report.source do
        logic do
          [
           '!',
           '==',
           'const_missing',
           'try',
           'to_s',
           'zebra',
           'const_get',
           '_output'
          ]
        end
      end

      @report.output('name') do
        element
      end

      source_data = @report._data(@report._source).source
      final = @report._sort('name', @report._output(source_data))

      final.should == [
                       '!',
                       '==',
                       '_output',
                       'const_get',
                       'const_missing',
                       'to_s',
                       'try',
                       'zebra'
                      ].map {|e| {'name' => e}}
    end

    it "should handle multiple sorts" do
      @report.source do
        logic do
          [
           {'country' => 'USA',    'name' => 'Tinker'},
           {'country' => 'Sweden', 'name' => 'Charmander'},
           {'country' => 'USA',    'name' => 'Pikachu'},
           {'country' => 'Norway', 'name' => 'Slink'},
           {'country' => 'Sweden', 'name' => 'Katarina'},
           {'country' => nil,      'name' => 'Slyfox'}
          ]
        end
      end

      @report.output('country') do
        element['country']
      end

      @report.output('name') do
        element['name']
      end

      source_data = @report._data(@report._source).source
      final = @report._sort(['country', 'name'], @report._output(source_data))

      final.should == [
                       {'country' => nil,      'name' => 'Slyfox'},
                       {'country' => 'Norway', 'name' => 'Slink'},
                       {'country' => 'Sweden', 'name' => 'Charmander'},
                       {'country' => 'Sweden', 'name' => 'Katarina'},
                       {'country' => 'USA',    'name' => 'Pikachu'},
                       {'country' => 'USA',    'name' => 'Tinker'},
                      ]
    end
  end
end
