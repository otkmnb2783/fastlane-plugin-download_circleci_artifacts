# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/download_circleci_artifacts/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-download_circleci_artifacts'
  spec.version       = Fastlane::DownloadCircleciArtifacts::VERSION
  spec.author        = %q{Manabu OHTAKE}
  spec.email         = %q{manabu2783@hotmail.com}

  spec.summary       = %q{Downloads a Circle CI artifact's}
  spec.homepage      = "https://github.com/otkmnb2783/fastlane-plugin-download_circleci_artifacts"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  spec.add_dependency 'circleci'
  spec.add_dependency 'fastlane-plugin-download_file'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'fastlane', '>= 2.17.0'
end
