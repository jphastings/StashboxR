require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "stashboxr"
    gem.summary = %Q{A ruby api for the stashbox.org website}
    gem.description = %Q{Upload files to stashbox.org and manage their metadata. User accounts or anonymous uploads!}
    gem.email = "jphastings@gmail.com"
    gem.homepage = "http://github.com/jphastings/StashboxR"
    gem.authors = ["JP Hastings-Spital"]
    gem.add_dependency "mechanize",'>= 1.0.0'
    gem.add_development_dependency "Shoulda"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test