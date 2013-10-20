#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = (Dir["test/*.rb"] + Dir["test/fluent/plugin/*.rb"] - ["helper.rb"]).sort
  t.verbose = true
  #t.warning = true
end

task :default => [:test]