# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-in-udp-event"
  gem.version       = File.read("VERSION").strip
  gem.authors       = ["Alexander Blagoev"]
  gem.email         = ["alexander.i.blagoev@gmail.com"]
  gem.summary       = %q{Event driven udp input plugin for fluentd}
  gem.description   = gem.summary
  gem.homepage      = "https://github.com/ablagoev/fluent-plugin-in-udp-event"
  gem.date          = '2013-10-20'

  gem.files         = [
    "lib/fluent/plugin/in_udp_event.rb",
    "Gemfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "fluent-plugin-in-udp-event.gemspec",
    "test/helper.rb",
    "test/fluent/plugin/test_in_udp_event.rb"
  ]

  gem.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]

  gem.licenses = ["MIT"]

  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"

  gem.add_runtime_dependency(%q<cool.io>, ["~> 1.1.1"])
  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "json"
end