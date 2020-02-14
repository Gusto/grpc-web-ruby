# frozen_string_literal: true

require 'spec_helper'

require 'grpc_web/client/client'
require 'hello_services_pb'
require 'test_grpc_server'
require 'test_hello_service'

RSpec.describe 'connecting to an envoy server from a ruby client', type: :feature do
  subject { client.say_hello(name: name) }

  around do |example|
    server = TestGRPCServer.new(service)
    server.start
    sleep 1
    example.run
    server.stop
  end

  let(:service) { TestHelloService }
  let(:client) { GRPCWeb::Client.new('http://envoy:8080', HelloService::Service) }
  let(:name) { "Jamesasdfas\u1f61ddfasdfas" }

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
