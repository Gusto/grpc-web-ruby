# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'connecting to a ruby server from a javascript client', type: :feature do
  subject(:perform_request) do
    visit(test_page) # Visit a static HTML page that loads the gRPC-Web client JS
    execute_script(js_script) # Make a gRPC-Web Request
    response # Wait for result
    nil
  end

  # Script to initialize a JS client in the browser and make a request
  let(:js_script) do
    <<-EOF
    var helloService = new #{js_client_class}('http://#{server_host}:#{server.port}', null, null);
    #{js_grpc_call}
    EOF
  end

  # JS snippet to make the gRPC-Web call
  let(:js_grpc_call) do
    <<-EOF
    var x = new HelloRequest();
    x.setName('#{name}');
    window.grpcResponse = null;
    helloService.sayHello(x, {}, function(err, response){
      window.grpcError = err;
      window.grpcResponse = response;
    });
    EOF
  end

  # We need to poll for the result since JS client calls are executed async
  def poll_for_js_result(script)
    result = nil
    20.times do # 2 sec timeout
      result = evaluate_script(script)
      break unless result.nil?

      sleep 0.1
    end
    result
  end

  let(:response) { poll_for_js_result('window.grpcResponse && window.grpcResponse.toObject()') }
  let(:js_error) { poll_for_js_result('window.grpcError') }

  let(:service) { TestHelloService }
  let(:rack_app) { TestGRPCWebApp.build(service) }

  # Use Capybara's built-in server instead of creating a separate session.
  # This avoids creating multiple WebDriver connections that exhaust Selenium's capacity.
  let(:server) do
    # Start a Capybara server for our rack app
    Capybara::Server.new(rack_app).tap(&:boot)
  end
  let(:server_host) { CapybaraServerHelper.server_host_for_browser(server) }

  let(:test_page) { "http://#{server_host}:#{server.port}/js-client/test.html" }
  let(:name) { "James\u1f61d" }

  shared_context 'javascript integration' do
    it 'returns the expected response from the service' do
      perform_request
      expect(response).to eq('message' => "Hello #{name}")
    end

    context 'for a method that raises a standard gRPC error' do
      let(:service) do
        Class.new(TestHelloService) do
          def say_hello(_request, _metadata = nil)
            raise ::GRPC::InvalidArgument, 'Test message'
          end
        end
      end

      it 'returns an error' do
        perform_request
        expect(js_error).to include('code' => 3, 'message' => 'Test message')
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
        perform_request
        expect(js_error).to include('code' => 2, 'message' => 'RuntimeError: Some random error')
      end
    end

    context 'for a method with empty request and response protos' do
      let(:js_grpc_call) do
        <<-EOF
        var x = new EmptyRequest();
        window.grpcResponse = null;
        helloService.sayNothing(x, {}, function(err, response){
          window.grpcError = err;
          window.grpcResponse = response;
        });
        EOF
      end

      it 'returns the expected response from the service' do
        perform_request
        expect(response).to eq({})
      end
    end
  end

  context 'with application/grpc-web-text format' do
    let(:js_client_class) { 'HelloServiceClientWebText' }

    it 'makes a request using application/grpc-web-text content type' do
      expect(GRPCWeb::GRPCRequestProcessor).to \
        receive(:process) \
        .with(have_attributes(content_type: 'application/grpc-web-text')) \
        .and_call_original
      perform_request
    end

    include_context 'javascript integration'
  end

  context 'with application/grpc-web+proto format' do
    let(:js_client_class) { 'HelloServiceClientWeb' }

    it 'makes a request using application/grpc-web+proto content type' do
      expect(GRPCWeb::GRPCRequestProcessor).to \
        receive(:process) \
        .with(have_attributes(content_type: 'application/grpc-web+proto')) \
        .and_call_original
      perform_request
    end

    include_context 'javascript integration'
  end
end
