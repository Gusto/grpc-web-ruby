#!/usr/bin/env ruby

lib_path = File.expand_path('lib', __dir__)
pb_path = File.expand_path('spec/pb-ruby', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
$LOAD_PATH.unshift(pb_path) unless $LOAD_PATH.include?(pb_path)

require 'grpc_web/client'
require 'hello_services_pb'

client = GRPCWeb::Client.new('http://localhost:8080', HelloService)
puts client.say_hello(name: 'James')
