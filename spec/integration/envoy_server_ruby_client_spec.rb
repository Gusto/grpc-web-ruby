require 'spec_helper'

require 'envoy_runner'
require 'grpc_web/client'
require 'hello_services_pb'
require 'test_grpc_server'
require 'test_hello_service'

describe 'connecting to an envoy server from a ruby client', type: :feature do
  # In order to perform these tests we need to run both a ruby gRPC Server
  # thread and an Envoy proxy (in docker) to proxy gRPC Web -> gRPC.
  around(:each) do |example|
    EnvoyRunner.start_envoy
    server = TestGRPCServer.new(service)
    server.start
    sleep 1
    example.run
    server.stop
    EnvoyRunner.stop_envoy
  end

  subject { client.say_hello(name: name) }

  let(:service) { TestHelloService }
  let(:client) { GRPCWeb::Client.new("http://localhost:8080", HelloService) }
  let(:name) { 'Jamesasdfasdfasdfas' }

  it 'returns the expected response from the service' do
    result = client.say_hello(name: name)
    expect(result).to eq(HelloResponse.new(message: "Hello #{name}"))
  end

  context 'for a method that raises a standard gRPC error' do
    let(:service) do
      Class.new(TestHelloService) do
        def say_hello(request, _metadata = nil)
          raise ::GRPC::InvalidArgument, 'Test message'
        end
      end
    end

    it 'raises an error' do
      expect{ subject }.to raise_error(GRPC::InvalidArgument, '3:Test message')
    end
  end

  context 'for a method that raises a custom error' do
    let(:service) do
      Class.new(TestHelloService) do
        def say_hello(request, _metadata = nil)
          raise 'Some random error'
        end
      end
    end

    it 'raises an error' do
      expect{ subject }.to raise_error(GRPC::Unknown, '2:RuntimeError: Some random error')
    end
  end
end
