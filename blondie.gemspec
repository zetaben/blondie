Gem::Specification.new do |gem|
  gem.name        = 'blondie'
  gem.version     = '0.0.1'
  gem.date        = '2014-01-14'
  gem.summary     = 'A searchlogic-like gem for Rails 4'
  gem.description = 'A searchlogic-like gem for Rails 4'
  gem.authors     = ['Benoît Dinocourt']
  gem.email       = 'ghrind@gmail.com'

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activerecord', '4.0.2'

  gem.add_development_dependency 'sqlite3', '1.3.8'
  gem.add_development_dependency 'rspec', '2.14.1'
end