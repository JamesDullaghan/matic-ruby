# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'matic/version'

Gem::Specification.new do |spec|
  spec.name          = "matic-ruby"
  spec.version       = Matic::VERSION
  spec.authors       = ["James Dullaghan", "Rutul Dave", "Bret Doucette", "Puneet Sutar"]
  spec.email         = ["james@himaxwell.com", "puneet@bigbinary.com", "bret@himaxwell.com", "rutul@himaxwell.com"]

  spec.summary       = %q{Matic Insurance Ruby Bindings}
  spec.description   = %q{Ruby bindings for Matic Quoting Service. Matic Quoting Service is HTTP RESTful API to provide a homeowners insurance quote.}
  spec.homepage      = "https://github.com/himaxwell/matic-ruby"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "curb"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "pry"
end
