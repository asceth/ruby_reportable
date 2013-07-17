$:.push File.expand_path("../lib", __FILE__)
require "ruby_reportable/version"

Gem::Specification.new do |s|
  s.name        = "ruby_reportable"
  s.version     = RubyReportable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.authors     = ["John 'asceth' Long"]
  s.email       = ["machinist@asceth.com"]
  s.homepage    = "http://github.com/asceth/ruby_reportable"
  s.summary     = "Ruby Reporting"
  s.description = "Allows you to write reports that use existing ruby classes/methods to present/filter the data"

  s.rubyforge_project = "ruby_reportable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rr'
end
