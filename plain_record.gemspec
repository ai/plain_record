require './lib/plain_record/version'

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name     = 'plain_record'
  s.version  = PlainRecord::VERSION
  s.date     = Time.now.strftime('%Y-%m-%d')
  s.summary  = 'Data persistence, which use human editable and ' +
               'readable plain text files.'
  s.description = <<-EOF
    Plain Record is a data persistence, which use human editable and
    readable plain text files. It's ideal for static generated sites,
    like blog or homepage.
  EOF

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = ['README.md', 'LICENSE', 'ChangeLog']
  s.require_path     = 'lib'

  s.author   = 'Andrey "A.I." Sitnik'
  s.email    = 'andrey@sitnik.ru'
  s.homepage = 'https://github.com/ai/plain_record'

  s.add_development_dependency "bundler",   [">= 1.0.10"]
  s.add_development_dependency "yard",      [">= 0"]
  s.add_development_dependency "rake",      [">= 0"]
  s.add_development_dependency "rspec",     [">= 0"]
  s.add_development_dependency "redcarpet", [">= 0"]
  s.add_development_dependency "r18n-core", [">= 0"]
  s.add_development_dependency "i18n",      [">= 0"]
end
