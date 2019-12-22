require 'spec_helper'

describe 'connecting to a ruby server from a javascript client', type: :feature do
  let(:server) { Capybara.current_session.server }
  let(:test_page) { File.expand_path('../js-client/test.html', __dir__) }
  let(:name) { 'James' }
  
  let(:js_script) do
    <<-EOF
    var helloService = new HelloServiceClient('http://#{server.host}:#{server.port}', null, null);
    var x = new HelloRequest();
    x.setName('#{name}');
    helloService.sayHello(x, {}, function(err, response){ window.grpcResponse = response; });
    EOF
  end

  it 'returns the expected response from the service' do
    visit "file://#{test_page}"
    execute_script(js_script)
    sleep 1
    result = evaluate_script("window.grpcResponse.toObject()")
    expect(result).to eq('message' => 'Hello James')
  end
end
