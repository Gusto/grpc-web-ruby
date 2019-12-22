require 'spec_helper'

describe 'connecting to a ruby server from a javascript client', type: :feature do
  let(:server) { Capybara.current_session.server }
  let(:test_page) { File.expand_path('../js-client/test.html', __dir__) }
  let(:name) { 'James' }

  # Script to initialize a JS client in the browser and make a request
  let(:js_script) do
    <<-EOF
    var helloService = new #{js_client_class}('http://#{server.host}:#{server.port}', null, null);
    var x = new HelloRequest();
    x.setName('#{name}');
    helloService.sayHello(x, {}, function(err, response){ window.grpcResponse = response; });
    EOF
  end

  # We need to poll for the result since JS client calls are executed async
  def js_result
    result = nil
    20.times do
      result = evaluate_script("window.grpcResponse && window.grpcResponse.toObject()")
      break unless result.nil?
      sleep 0.1
    end
    result
  end

  context 'with application/grpc-web-text format' do
    let(:js_client_class) { 'HelloServiceClientWebText' }

    it 'returns the expected response from the service' do
      visit "file://#{test_page}"
      execute_script(js_script)
      expect(js_result).to eq('message' => 'Hello James')
    end
  end

  context 'with application/grpc-web format' do
    let(:js_client_class) { 'HelloServiceClientWeb' }

    it 'returns the expected response from the service' do
      visit "file://#{test_page}"
      execute_script(js_script)
      expect(js_result).to eq('message' => 'Hello James')
    end
  end
end
