require 'spec_helper'

require 'envoy_runner'
require 'grpc_web/client'
require 'hello_services_pb'
require 'test_grpc_server'

describe 'connecting to a ruby server from a ruby client', type: :feature do
  # In order to perform these tests we need to run both a ruby gRPC Server
  # thread and an Envoy proxy (in docker) to proxy gRPC Web -> gRPC.
  around(:all) do |example|
    EnvoyRunner.start_envoy
    server = TestGRPCServer.new
    server.start
    example.run
    server.stop
    EnvoyRunner.stop_envoy
  end

  let(:client) { GRPCWeb::Client.new("http://localhost:8080", HelloService) }
  let(:name) { 'Jamesasdfasdfasdfas' }

  it 'returns the expected response from the service' do
    result = client.say_hello(name: name)
    expect(result).to eq(HelloResponse.new(message: "Hello #{name}"))
  end
end
