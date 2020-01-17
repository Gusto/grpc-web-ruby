# frozen_string_literal: true

require 'grpc'

# Used to build a Rack app hosting the HelloService for integration testing.
class TestGRPCServer < ::GRPC::RpcServer
  attr_accessor :thread

  def initialize(service)
    super()
    add_http2_port('0.0.0.0:9090', :this_port_is_insecure)
    handle(service)
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
