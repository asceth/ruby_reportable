Ruby Reportable - reporting in ruby
===================================


## DESCRIPTION

Ruby Reportable is a DSL for writing reports using pure ruby.  It allows you to use
existing code (ie your Rails application) to grab data and the manipulate it.

If you have loaded it then Ruby Reportable can report on it.


## Examples

See examples/ directory

## Usage

Using Ruby Reportable is as easy as ```include RubyReportable``` in a new class.  The include lets Ruby Reportable know this class is a new report and also brings in the DSL.

### Source

Your source is the start of your data.  All available configuration is shown below.

```ruby
source do
  #
  # define how your outputs will see each element of the source data
  #
  as :element  # this is the default

  # Whatever you want your starting data to be
  logic do
    ObjectSpace.each_object.to_a.group_by(&:class).to_a
  end
end
```

## INSTALLATION

Install as a gem or use as part of your Gemfile

    $ [sudo] gem install ruby_reportable




