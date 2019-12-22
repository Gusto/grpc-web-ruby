require 'spec_helper'
require 'grpc_web/client'
require 'hello_services_pb'

describe 'connecting to a ruby server from a ruby client', type: :feature do
  let(:server) { Capybara.current_session.server }
  let(:client) { GRPCWeb::Client.new("http://#{server.host}:#{server.port}", HelloService) }
  let(:name) { 'James' }

  it 'returns the expected response from the service' do
    Capybara.current_session
    result = client.say_hello(name: 'James')
    expect(result).to eq(HelloResponse.new(message: 'Hello James'))
  end
end
