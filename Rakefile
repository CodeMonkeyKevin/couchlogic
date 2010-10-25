require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "couchlogic"
  gem.summary = %Q{An advanced Ruby interface for CouchDB}
  gem.description = %Q{An advanced Ruby interface for CouchDB.}
  gem.email = "mgomes@geminisbs.com"
  gem.homepage = "http://github.com/mgomes/couchlogic"
  gem.authors = ["Mauricio Gomes"]
  
  gem.add_runtime_dependency "yajl-ruby", "~> 0.7.8"
  gem.add_runtime_dependency "curb", "~> 0.7.8"
  
  gem.add_development_dependency "rspec", "~> 2.0.0"
  gem.add_development_dependency "bundler", "~> 1.0.0"
  gem.add_development_dependency "jeweler", "~> 1.5.0.pre5"
  
  gem.files = FileList['lib/**/*.rb', 'VERSION', 'LICENSE', "README.rdoc"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "test #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
