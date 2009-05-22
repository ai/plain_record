# encoding: utf-8
gem 'rspec'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ['--format', 'specdoc', '--colour']
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
end

Rake::RDocTask.new do |rdoc|
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('*.rdoc', 'lib/**/*.rb')
  rdoc.title = 'Plain Record'
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--charset=utf-8'
  rdoc.options << '--all'
  rdoc.options << '--inline-source'
end

require File.join(File.dirname(__FILE__), 'lib', 'plain_record', 'version')

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'plain_record'
  s.version = PlainRecord::VERSION
  s.summary = 'Data persistence, which use human editable and ' +
              'readable plain text files.'
  s.description = <<-DESC
      Plain Record is a data persistence, which use human editable and readable
      plain text files. It’s ideal for static generated sites, like blog or
      homepage.
    DESC
  
  s.files = FileList[
    'lib/**/*',
    'spec/**/*',
    'Rakefile',
    'LICENSE',
    'README.rdoc']
  s.test_files = FileList['spec/**/*']
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE']
  s.require_path = 'lib'
  s.has_rdoc = true
  s.rdoc_options << '--title "Plain Record"' << '--main README.rdoc' <<
                    '--charset=utf-8' << '--all' << '--inline-source'
  
  s.author = 'Andrey "A.I." Sitnik'
  s.email = 'andrey@sitnik.ru'
  s.homepage = 'http://github.com/ai/plain_record'
  s.rubyforge_project = 'plainrecord'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end
