require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "SABnzbd"
    s.summary = "Ruby interface to the SABnzbd usenet client"
    s.email = "sutto@sutto.net"
    s.homepage = "http://github.com/Sutto/SABnzbd"
    s.description = "Ruby interface to the SABnzbd usenet client"
    s.authors = ["Darcy Laycock"]
    s.add_dependency 'httparty'
    s.files = FileList["[A-Z]*.*", "{example,lib,test}/**/*"] 
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Jeweler'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
