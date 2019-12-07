pb_path = File.expand_path('../pb-ruby', __dir__)
lib = File.expand_path('../../lib', __dir__)
$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
$LOAD_PATH.unshift(pb_path) unless $LOAD_PATH.include?(pb_path)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rack'
require 'grpc-web'
require 'test_hello_service'

app = GRPCWeb::RackApp.for_services([
  proc { TestHelloService.new },
])

Rack::Handler::WEBrick.run app
