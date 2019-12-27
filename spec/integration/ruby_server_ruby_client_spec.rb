require 'spec_helper'
require 'grpc_web/client'
require 'hello_services_pb'

describe 'connecting to a ruby server from a ruby client', type: :feature do
  let(:service) { TestHelloService }
  let(:rack_app) { TestGRPCWebApp.build(service) }
  let(:browser) { Capybara::Session.new(Capybara.default_driver, rack_app) }
  let(:server) { browser.server }

  let(:client) { GRPCWeb::Client.new("http://#{server.host}:#{server.port}", HelloService::Service) }
  let(:name) { 'James' }

  subject(:response) { client.say_hello(name: name) }

  it 'returns the expected response from the service' do
    expect(response).to eq(HelloResponse.new(message: "Hello #{name}"))
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
