require "bundler"
Bundler.setup

require "rspec"
require "rspec/core/rake_task"

Rspec::Core::RakeTask.new(:spec)

gemspec = eval(File.read(File.join(Dir.pwd, "ruby_reportable.gemspec")))

task :build => "#{gemspec.full_name}.gem"

task :test => :spec

file "#{gemspec.full_name}.gem" => gemspec.files + ["ruby_reportable.gemspec"] do
  system "gem build ruby_reportable.gemspec"
  system "gem install ruby_reportable-#{RubyReportable::VERSION}.gem"
end

