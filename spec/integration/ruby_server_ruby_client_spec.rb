# frozen_string_literal: true

require 'spec_helper'
require 'grpc_web/client'
require 'hello_services_pb'

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

  let(:client) do
    GRPCWeb::Client.new(
      "http://{basic_username}:#{basic_password}@#{server.host}:#{server.port}",
      HelloService::Service,
    )
  end
  let(:name) { 'James' }

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
end
