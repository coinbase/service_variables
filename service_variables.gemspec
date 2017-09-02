# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'service_variables'
  s.version     = '1.0.0'
  s.date        = '2017-04-20'
  s.summary     = 'Service level variables.'
  s.description = 'Wrapper for redis backed configuration variables accessible to multiple servers.'
  s.authors     = ['coinbase']
  s.email       = 'opensource@coinbase.com'
  s.homepage    = 'https://github.com/coinbase/service_variables'
  s.license     = 'Apache-2.0'

  s.files = ['lib/service_variables.rb']

  s.add_dependency 'redis', '~> 4.0'
  s.add_development_dependency 'bundler', '~> 1.14'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop', '~> 0.41'
end
