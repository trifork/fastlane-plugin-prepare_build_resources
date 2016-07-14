# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/prepare_build_resources/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-prepare_build_resources'
  spec.version       = Fastlane::PrepareBuildResources::VERSION
  spec.author        = %q{Jakob Jensen}
  spec.email         = %q{jje@trifork.com}

  spec.summary       = %q{Prepares certificates and provisioning profiles for building and removes them afterwards.}
  spec.homepage      = "https://github.com/CodeReaper/fastlane-plugin-prepare_build_resources"
  spec.license       = "Apache-2.0"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'fastlane', '>= 1.97.2'
end
