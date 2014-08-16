# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smml/version'

Gem::Specification.new do |spec|
  spec.name          = "smml"
  spec.version       = Smml::VERSION
  spec.authors       = ["tabasano"]
  spec.email         = ["pianotoieba+smml@gmail.com"]
  spec.summary       = %q{Simple MML to MIDI}
  spec.description   = %q{compile a Music Macro Language file to a Standard MIDI file.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir.glob("lib/*")+Dir.glob("lib/smml/*")+["Gemfile","Rakefile","LICENSE.TXT","smml.gemspec"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
end
