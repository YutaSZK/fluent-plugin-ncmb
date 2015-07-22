# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-ncmb"
  spec.version       = "0.1.0"
  spec.authors       = ["suzuki.yuta", "goya.tomohiro"]
  spec.email         = ["suzuki.yuta@nifty.co.jp", "goya.tomohiro@nifty.co.jp"]
  spec.description   = "fluentd plugin for NIFTY Cloud mobile backend"
  spec.summary       = spec.description
  spec.homepage      = 'http://mb.cloud.nifty.com/'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "fluentd", [">= 0.10.9", "< 2"]
  spec.add_development_dependency "ncmb-ruby-client", "~> 0.1"
  spec.add_development_dependency "test-unit-rr", '~> 1.0'
end
