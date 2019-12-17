#!/usr/bin/env ruby

support_path = File.expand_path('spec/support', __dir__)
pb_path = File.expand_path('spec/pb-ruby', __dir__)
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(support_path) unless $LOAD_PATH.include?(support_path)
$LOAD_PATH.unshift(pb_path) unless $LOAD_PATH.include?(pb_path)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'test_grpc_web_app'
Rack::Handler::WEBrick.run TestGRPCWebApp.build
