Gem::Specification.new do |s|
  s.name          = 'leaseweb-rest-api'
  s.version       = '1.1.1'
  s.authors       = 'Arnoud Vermeer'
  s.email         = 'a.vermeer@tech.leaseweb.com'
  s.license       = 'Apache'
  s.summary       = 'Leaseweb REST API client for Ruby'
  s.description   = 'Leaseweb REST API client for Ruby.'
  s.homepage      = 'https://github.com/LeaseWeb/leaseweb-rest-api'

  s.files         = `git ls-files`.split("\n")

  s.add_dependency 'httparty'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'
end
