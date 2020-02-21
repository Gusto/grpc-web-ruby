# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'hello_services_pb'

RSpec.describe 'connecting to a ruby server from a nodejs client', type: :feature do
  subject(:json_result) { `#{node_cmd}` }

  let(:node_client) { File.expand_path('../node-client/dist/client.js', __dir__) }
  let(:node_cmd) do
    [
      'node',
      node_client,
      server_url,
      name,
      basic_username,
      basic_password,
    ].join(' ')
  end
  let(:result) { JSON.parse(json_result) }

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
  let(:server_url) { "http://#{server.host}:#{server.port}" }
  let(:name) { "James\u1f61d" }

  it 'returns the expected response from the service' do
    expect(result['response']).to eq('message' => "Hello #{name}")
  end

  context 'with a service that raises a standard gRPC error' do
    let(:service) do
      Class.new(TestHelloService) do
        def say_hello(_request, _metadata = nil)
          raise ::GRPC::InvalidArgument, 'Test message'
        end
      end
    end

    it 'raises an error' do
      expect(result['error']).to include('grpc-message' => ['Test message'], 'grpc-status' => ['3'])
    end
  end

  context 'with a service that raises a custom error' do
    let(:service) do
      Class.new(TestHelloService) do
        def say_hello(_request, _metadata = nil)
          raise 'Some random error'
        end
      end
    end

    it 'raises an error' do
      expect(result['error']).to include(
        'grpc-message' => ['RuntimeError: Some random error'],
        'grpc-status' => ['2'],
      )
    end
  end
end
