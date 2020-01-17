# frozen_string_literal: true

require 'spec_helper'

require 'grpc_web/client'
require 'hello_services_pb'
require 'test_grpc_server'
require 'test_hello_service'

<<<<<<< HEAD
describe 'connecting to an envoy server from a ruby client', type: :feature do
=======
RSpec.describe 'connecting to an envoy server from a ruby client', type: :feature do
  subject { client.say_hello(name: name) }

>>>>>>> Fix rspecs
  # In order to perform these tests we need to run both a ruby gRPC Server
  # thread and an Envoy proxy (in docker) to proxy gRPC Web -> gRPC.
<<<<<<< HEAD
  subject { client.say_hello(name: name) }

  around do |example|
    EnvoyRunner.start_envoy
=======
  around(:each) do |example|
>>>>>>> Try running specs using docker-compose
    server = TestGRPCServer.new(service)
    server.start
    sleep 1
    example.run
    server.stop
  end

  let(:service) { TestHelloService }
<<<<<<< HEAD
  let(:client) { GRPCWeb::Client.new('http://localhost:8080', HelloService::Service) }
=======
  let(:client) { GRPCWeb::Client.new("http://envoy:8080", HelloService::Service) }
>>>>>>> Try running specs using docker-compose
  let(:name) { 'Jamesasdfasdfasdfas' }

  it 'returns the expected response from the service' do
    result = client.say_hello(name: name)
    expect(result).to eq(HelloResponse.new(message: "Hello #{name}"))
  end

  context 'for a method that raises a standard gRPC error' do
    let(:service) do
      Class.new(TestHelloService) do
        def say_hello(_request, _metadata = nil)
          raise ::GRPC::InvalidArgument, 'Test message'
        end
      end
    end

    it 'raises an error' do
      expect { subject }.to raise_error(GRPC::InvalidArgument, '3:Test message')
    end
  end

  context 'for a method that raises a custom error' do
    let(:service) do
      Class.new(TestHelloService) do
        def say_hello(_request, _metadata = nil)
          raise 'Some random error'
        end
      end
    end

    it 'raises an error' do
      expect { subject }.to raise_error(GRPC::Unknown, '2:RuntimeError: Some random error')
    end
  end
end
