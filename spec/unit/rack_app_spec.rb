require 'rack/mock'
require 'grpc_web/rack_app'
require 'test_hello_service'

RSpec.describe(::GRPCWeb::RackApp) do
  let(:app) { described_class.new }
  let(:mock_app) { Rack::MockRequest.new(app) }
  let(:mock_response) { mock_app.post('/HelloService/SayHello', input: 'request input', lint: true, fatal: true) }
  let(:service_response) { [200, {}, ['hello']] }
  let(:service_class) {TestHelloService}
  let(:service_class_instance) { service_class.new }
  let(:service_cache) { {service_class_instance: nil}}

  shared_context 'given a class' do
    let(:handle) { app.handle(service_class) }
  end

  shared_context 'given an instance of a class' do
    let(:handle) { app.handle(service_class_instance) }
  end

  shared_context 'given a class and a lazy init block' do
    let(:handle) do
      app.handle(service_class) do
        service_cache[:service_class_instance] ||= service_class.new
      end
    end
  end

  shared_context 'given an instance of a class and a lazy init block' do
    let(:handle) do
      app.handle(service_class_instance) do
        service_cache[:service_class_instance] ||= service_class.new
      end
    end
  end

  describe 'validation' do
    subject { handle }
    context 'given a class' do
      include_context 'given a class'

      it 'validates the class' do
        expect(::GRPCWeb::ServiceClassValidator).to receive(:validate).with(service_class)
        subject
      end
    end

    context 'given an instance of a class' do
      include_context 'given an instance of a class'
      it 'validates the class of the instance' do
        expect(::GRPCWeb::ServiceClassValidator).to receive(:validate).with(service_class)
        subject
      end
    end

    context 'given a class and a lazy init block' do
      include_context 'given a class and a lazy init block'
      it 'validates the class' do
        expect(::GRPCWeb::ServiceClassValidator).to receive(:validate).with(service_class)
        subject
      end
    end

    context 'given an instance of a class and a lazy init block' do
      include_context 'given an instance of a class and a lazy init block'
      it 'validates the class' do
        expect(::GRPCWeb::ServiceClassValidator).to receive(:validate).with(service_class)
        subject
      end
    end
  end

  describe 'routing' do
    before { handle }
    subject{mock_response}
    let(:expected_env) {hash_including({'rack.input'=>satisfy{|input| input.read == 'request input'}})}

    context 'given a class' do
      include_context 'given a class'
      it 'creates an instance of the class and calls the correct method on it' do
        expect(::GRPCWeb::RackHandler).to receive(:call)
          .with(an_instance_of(TestHelloService), :SayHello, expected_env)
          .and_return(service_response)
        subject
      end
    end

    context 'given an instance of a class' do
      include_context 'given an instance of a class'

      it 'calls the correct method on the instance' do
        expect(::GRPCWeb::RackHandler).to receive(:call).
          with(service_class_instance, :SayHello, expected_env).and_return(
          service_response
        )
        subject
      end
    end

    context 'given a class and a lazy init block' do
      include_context 'given a class and a lazy init block'

      it 'calls the init block to instantiate the service and calls the correct method on it' do
        expect(::GRPCWeb::RackHandler).to receive(:call) do |service, service_method, env|
          expect([service, service_method, env]).
            to match([service_cache[:service_class_instance], :SayHello, expected_env])
          service_response
        end
        subject
      end
    end

    context 'given an instance of a class and a lazy init block' do
      include_context 'given an instance of a class and a lazy init block'

      it 'calls the init block to instantiate the service and calls the correct method on it' do
        expect(::GRPCWeb::RackHandler).to receive(:call) do |service, service_method, env|
          expect([service, service_method, env]).
            to match([service_cache[:service_class_instance], :SayHello, expected_env])
          service_response
        end
        subject
      end

      it 'does not call the instance given' do
        allow(::GRPCWeb::RackHandler).to receive(:call).and_return(service_response)
        expect(::GRPCWeb::RackHandler).to_not receive(:call).
          with(service_class_instance, any_args)
        subject
      end
    end
  end

  describe 'response' do
    shared_examples_for 'a successful response' do
      it 'returns a successful response' do
        expect(mock_response.status).to eq(200)
      end
      it 'returns the response body correctly' do
        expect(mock_response.body).to eq('hello')
      end
    end
    subject{mock_response}

    before do
      handle
      allow(::GRPCWeb::RackHandler).to receive(:call).and_return(service_response)
    end

    context 'given a class' do
      include_context 'given a class'
      it_behaves_like 'a successful response'
    end

    context 'given an instance of a class' do
      include_context 'given an instance of a class'
      it_behaves_like 'a successful response'
    end

    context 'given a class and a lazy init block' do
      include_context 'given a class and a lazy init block'
      it_behaves_like 'a successful response'
    end

    context 'given an instance of a class and a lazy init block' do
      include_context 'given an instance of a class and a lazy init block'
      it_behaves_like 'a successful response'
    end
  end
end
