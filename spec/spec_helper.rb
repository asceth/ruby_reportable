require 'rubygems'
require 'bundler'
Bundler.setup

require 'rspec'
require 'ruby_reportable'

RSpec.configure do |config|
  config.mock_with :rr
end
