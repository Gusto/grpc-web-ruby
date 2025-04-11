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
      grpc_method,
      basic_username,
      basic_password,
      name,
    ].join(' ')
  end
  let(:result) { JSON.parse(json_result) }

  let(:basic_password) { 'supersecretpassword' }
  let(:basic_username) { 'supermanuser' }
  let(:service) { TestHelloService }
  let(:grpc_method) { 'SayHello' }
  let(:rack_app) do
    app = TestGRPCWebApp.build(service)
    app.use Rack::Auth::Basic do |username, password|
      [username, password] == [basic_username, basic_password]
    end
    app
  end

  let(:server_url) { "http://#{Capybara.server_host}:#{Capybara.server_port}" }
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

  context 'with empty request and response protos' do
    let(:grpc_method) { 'SayNothing' }

    it 'returns the expected response from the service' do
      expect(result['response']).to eq({})
    end
  end
end
