# frozen_string_literal: true

RSpec.describe ::GRPCWeb::GRPCRequestProcessor do
  describe '#process' do
    subject(:process) { described_class.process(initial_call) }

    let(:initial_call) { instance_double(::GRPCWeb::GRPCWebCall, request: initial_request) }
    let(:initial_request) do
      instance_double(
        ::GRPCWeb::GRPCWebRequest,
        service_method: service_method,
        service: service,
        accept: request_accept,
        content_type: request_content_type,
      )
    end

    let(:text_coder) { ::GRPCWeb::TextCoder }
    let(:framing) { ::GRPCWeb::RequestFraming }
    let(:serialization) { ::GRPCWeb::MessageSerialization }

    let(:decoded_request) { instance_double(::GRPCWeb::GRPCWebRequest) }
    let(:unframed_request) { instance_double(::GRPCWeb::GRPCWebRequest) }
    let(:deserialized_request) do
      instance_double(
        ::GRPCWeb::GRPCWebRequest,
        service: service,
        service_method: service_method,
        body: instance_double(HelloRequest),
        content_type: request_content_type,
        accept: request_accept,
      )
    end
    let(:service) { instance_double(TestHelloService) }
    let(:service_method) { :SayHello }
    let(:request_content_type) { ::GRPCWeb::ContentTypes::JSON_CONTENT_TYPE }
    let(:request_accept) { '*/*' }
    let(:service_response) { HelloResponse.new(message: 'not hello') }
    let(:expected_initial_response) { instance_of(::GRPCWeb::GRPCWebResponse) }
    let(:serialized_response) { instance_double(::GRPCWeb::GRPCWebResponse) }
    let(:framed_response) { instance_double(::GRPCWeb::GRPCWebResponse) }
    let(:encoded_response) { instance_double(::GRPCWeb::GRPCWebResponse) }

    before do
      allow(text_coder).to receive(:decode_request).and_return(decoded_request)
      allow(framing).to receive(:unframe_request).and_return(unframed_request)
      allow(serialization).to receive(:deserialize_request).and_return(deserialized_request)
      allow(service).to receive(:say_hello).and_return(service_response)
      allow(serialization).to receive(:serialize_response).and_return(serialized_response)
      allow(framing).to receive(:frame_response).and_return(framed_response)
      allow(text_coder).to receive(:encode_response).and_return(encoded_response)
    end

    it 'decodes the initial request' do
      expect(text_coder).to receive(:decode_request).with(initial_request)
      process
    end

    it 'unframes the decoded request' do
      expect(framing).to receive(:unframe_request).with(decoded_request)
      process
    end

    it 'deserializes the unframed request' do
      expect(serialization).to receive(:deserialize_request).with(unframed_request)
      process
    end

    context 'when handler only accepts one parameter' do
      before { allow(service).to receive(:method).and_return(instance_double(Method, arity: 1)) }

      it 'executes the request' do
        expect(service).to receive(:say_hello).with(deserialized_request.body)
        process
      end
    end

    context 'when handler accepts more than one parameter' do

      it 'executes the request with additional metadata' do
        expect(service).to receive(:say_hello).with(deserialized_request.body, initial_call)
        process
      end
    end

    describe 'execution response' do
      shared_examples_for 'produces the expected initial response' do
        it 'produces the expected initial response' do
          expect(serialization).to receive(:serialize_response).with(
            ::GRPCWeb::GRPCWebResponse.new(expected_response_content_type, expected_response_body),
          )
          process
        end
      end

      shared_examples_for 'produces the expected initial response with the correct content type' do
        context 'when the request accept is nil' do
          let(:request_accept) { nil }

          it_behaves_like 'produces the expected initial response' do
            let(:expected_response_content_type) { request_content_type }
          end
        end

        context 'when the request accept is "*/*"' do
          let(:request_accept) { '*/*' }

          it_behaves_like 'produces the expected initial response' do
            let(:expected_response_content_type) { request_content_type }
          end
        end

        context 'when the request accept is ""' do
          let(:request_accept) { '' }

          it_behaves_like 'produces the expected initial response' do
            let(:expected_response_content_type) { request_content_type }
          end
        end

        context 'when the request accepts only a specific content type' do
          let(:request_accept) { ::GRPCWeb::ContentTypes::TEXT_PROTO_CONTENT_TYPE }

          it_behaves_like 'produces the expected initial response' do
            let(:expected_response_content_type) { request_accept }
          end
        end
      end

      context 'when the service returns a valid response' do
        before { allow(service).to receive(:say_hello).and_return(service_response) }

        it_behaves_like 'produces the expected initial response with the correct content type' do
          let(:expected_response_body) { service_response }
        end
      end

      context 'when the service raises an error' do
        let(:error) { StandardError.new('something went wrong') }
        let(:service) { instance_double(TestHelloService) }

        before { allow(service).to receive(:say_hello).and_raise(error) }

        it_behaves_like 'produces the expected initial response with the correct content type' do
          let(:expected_response_body) { error }
        end
        it 'calls the error handler' do
          expect(::GRPCWeb.on_error).to receive(:call).with(error, service, service_method)
          process
        end
      end
    end

    it 'serializes the initial response' do
      expect(serialization).to receive(:serialize_response).with(expected_initial_response)
      process
    end

    it 'frames the serialized response' do
      expect(framing).to receive(:frame_response).with(serialized_response)
      process
    end

    it 'encodes the framed response' do
      expect(text_coder).to receive(:encode_response).with(framed_response)
      process
    end

    it 'returns the encoded response' do
      expect(process).to eq(encoded_response)
    end
  end
end
