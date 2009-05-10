gem 'rspec'
require 'spec/rake/spectask'
require 'rake/rdoctask'

Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ['--format', 'specdoc', '--colour']
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
end

Rake::RDocTask.new do |rdoc|
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('*.rdoc', 'lib/**/*.rb')
  rdoc.title = 'Plain Record'
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--charset=utf-8' << '--all' << '--inline-source'
end
