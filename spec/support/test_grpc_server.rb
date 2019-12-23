require 'grpc'
require 'test_hello_service'

# Used to build a Rack app hosting the HelloService for integration testing.
class TestGRPCServer < ::GRPC::RpcServer
  attr_accessor :thread

  def initialize
    super
    self.add_http2_port('0.0.0.0:9090', :this_port_is_insecure)
    self.handle(TestHelloService)
  end

  def start
    return if thread
    grpc_server = self
    self.thread = Thread.new do
      grpc_server.run
    end
    self
  end

  def stop
    return unless thread
    super
    thread.join
  end
end
#
# x = TestGRPCServer.new.start
# sleep 10
# x.stop
