#!/usr/local/bin/ruby

require 'strut.rb'

command = ARGV.shift
filename = ARGV.shift

Dispatcher.new(Social, filename).dispatch(command)
