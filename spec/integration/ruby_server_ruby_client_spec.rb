# frozen_string_literal: true

require 'spec_helper'
require 'grpc_web/client/client'
require 'hello_services_pb'
require 'goodbye_services_pb'

RSpec.describe 'connecting to a ruby server from a ruby client', type: :feature do
  subject(:response) { client.say_hello(name: name) }

  let(:basic_password) { 'supersecretpassword' }
  let(:basic_username) { 'supermanuser' }
  let(:service) { TestHelloService }
  let(:rack_app) do
    app = TestGRPCWebApp.build(service)
    app.use Rack::Auth::Basic do |username, password|
      [username, password] == [basic_username, basic_password]
    end
    app
  end
  let(:browser) { Capybara::Session.new(Capybara.default_driver, rack_app) }
  let(:server) { browser.server }

  let(:client_url) { "http://#{basic_username}:#{basic_password}@#{server.host}:#{server.port}" }
  let(:client) do
    GRPCWeb::Client.new(
      client_url,
      HelloService::Service,
    )
  end
  let(:name) { "James\u1f61d" }

  it 'returns the expected response from the service' do
    expect(response).to eq(HelloResponse.new(message: "Hello #{name}"))
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

  context 'for a network error' do
    let(:client_url) { "http://#{basic_username}:#{basic_password}@#{server.host}:#{server.port + 1}" }

    it 'raises an error' do
      expect { subject }.to raise_error(GRPC::Unavailable, a_string_starting_with('14:Failed to open TCP connection'))
    end
  end

  context 'for an authentication error' do
    let(:client_url) { "http://#{basic_username}:#{basic_password + '1'}@#{server.host}:#{server.port}" }

    it 'raises an error' do
      expect { subject }.to raise_error(GRPC::Unauthenticated, a_string_starting_with('16:Unauthorized'))
    end
  end

  context 'for a service that is not implemented on the server' do
    let(:client) do
      GRPCWeb::Client.new(
        client_url,
        GoodbyeService::Service,
        )
    end
    subject(:response) { client.say_goodbye(name: name) }

    it 'raises an error' do
      expect { subject }.to raise_error(GRPC::Unavailable, a_string_starting_with('14:Not Found'))
    end
  end
end
