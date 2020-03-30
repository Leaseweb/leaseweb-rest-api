Gem::Specification.new do |s|
  s.name          = 'leaseweb-rest-api'
  s.version       = '2.0.0'
  s.authors       = 'Leaseweb Product Owners'
  s.email         = 'productowners@leaseweb.com'
  s.license       = 'Apache'
  s.summary       = 'Leaseweb REST API client for Ruby'
  s.description   = 'Leaseweb REST API client for Ruby.'
  s.homepage      = 'https://github.com/LeaseWeb/leaseweb-rest-api'

  s.files         = `git ls-files`.split("\n")

  s.add_dependency 'httparty'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'
end
