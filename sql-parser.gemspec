$:.push File.expand_path('../lib', __FILE__)
require 'sql-parser/version'

Gem::Specification.new do |s|
  s.name        = 'sql-parser'
  s.version     = SQLParser::VERSION
  s.authors     = ['Dray Lacy', 'Louis Mullie', "Chris O'Hara"]
  s.email       = ['dray@izea.com', 'louis.mullie@gmail.com', 'cohara@kissmetrics.com']
  s.homepage    = 'https://github.com/louismullie/sql-parser'
  s.summary     = %q{ Ruby library for parsing and generating SQL statements }
  s.description = %q{ A Racc-based Ruby parser and generator for SQL statements }

  s.files = Dir.glob('lib/**/*')

  s.add_runtime_dependency 'racc', '1.4.14'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'rexical', '1.0.5'
  s.add_development_dependency 'rake'
end
