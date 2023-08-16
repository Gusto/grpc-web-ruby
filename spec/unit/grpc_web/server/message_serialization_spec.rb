# frozen_string_literal: true

RSpec.describe ::GRPCWeb::MessageSerialization do
  describe '#deserialize_request' do
    subject(:deserialized_request) { described_class.deserialize_request(request) }

    let(:request) do
      ::GRPCWeb::GRPCWebRequest.new(
        service,
        service_method,
        content_type,
        accept,
        body,
      )
    end
    let(:service) { TestHelloService.new }
    let(:service_method) { :SayHello }
    let(:accept) { '*/*' }
    let(:body) do
      [
        ::GRPCWeb::MessageFrame.header_frame(''),
        ::GRPCWeb::MessageFrame.payload_frame(serialized_request_object),
      ]
    end
    let(:expected_request_body) { HelloRequest.new(name: 'Noa') }

    context 'when the content type is grpc-web+json' do
      let(:content_type) { ::GRPCWeb::ContentTypes::JSON_CONTENT_TYPE }
      let(:serialized_request_object) { '{"name":"Noa"}' }

      it 'returns an identical request except for the body' do
        expect([
          deserialized_request.service,
          deserialized_request.service_method,
          deserialized_request.content_type,
          deserialized_request.accept,
        ]).to eq([
          request.service,
          request.service_method,
          request.content_type,
          request.accept,
        ])
      end

      it 'deserializes the body' do
        expect(deserialized_request.body).to eq(expected_request_body)
      end
    end

    context 'when the content type is not grpc-web+json' do
      let(:content_type) { ::GRPCWeb::ContentTypes::TEXT_CONTENT_TYPE }
      let(:serialized_request_object) { "\n\x03Noa" }

      it 'returns an identical request except for the body' do
        expect([
          deserialized_request.service,
          deserialized_request.service_method,
          deserialized_request.content_type,
          deserialized_request.accept,
        ]).to eq([
          request.service,
          request.service_method,
          request.content_type,
          request.accept,
        ])
      end

      it 'deserializes the body' do
        expect(deserialized_request.body).to eq(expected_request_body)
      end
    end
  end

  describe '#serialize_response' do
    subject(:serialized_response) { described_class.serialize_response(response) }

    let(:response) do
      ::GRPCWeb::GRPCWebResponse.new(content_type, body)
    end
    let(:body) { HelloRequest.new(name: 'Noa') }

    shared_examples_for 'generates a body with a payload frame' do |expected_payload_frame_body|
      it 'generates a body with a payload frame' do
        expect(serialized_response.body).to be_a(Array)
        expect(serialized_response.body.find(&:payload?).body).to eq expected_payload_frame_body
      end
    end

    shared_examples_for 'generates a body without a payload frame' do
      it 'generates a body without a payload frame' do
        expect(serialized_response.body).to be_a(Array)
        expect(serialized_response.body.find(&:payload?)).to be_nil
      end
    end

    shared_examples_for 'generates a body with a header frame' do |expected_header_frame_body|
      it 'generates a body with a header frame' do
        expect(serialized_response.body).to be_a(Array)
        expect(serialized_response.body.find(&:header?).body).to eq expected_header_frame_body
      end
    end

    shared_examples_for 'serializes an exception' do
      context 'when response is a StandardError' do
        let(:body) { StandardError.new("I've made a huge mistake") }

        it_behaves_like 'generates a body without a payload frame'

        it_behaves_like(
          'generates a body with a header frame',
            "grpc-status:2\r\ngrpc-message:StandardError: I've made a huge mistake\r\n"\
            "x-grpc-web:1\r\n",
        )
      end

      context 'when response is a GRPC::BadStatus' do
        let(:body) { ::GRPC::NotFound.new('Where am I?', 'user-role-id' => '123') }

        it_behaves_like 'generates a body without a payload frame'

        it_behaves_like(
          'generates a body with a header frame',
            "grpc-status:5\r\ngrpc-message:Where am I?\r\nx-grpc-web:1\r\nuser-role-id:123\r\n",
        )
      end
    end

    context 'when the content type is grpc-web+json' do
      let(:content_type) { ::GRPCWeb::ContentTypes::JSON_CONTENT_TYPE }

      it_behaves_like(
        'generates a body with a payload frame',
        '{"name":"Noa"}',
      )
      it_behaves_like(
        'generates a body with a header frame',
        "grpc-status:0\r\ngrpc-message:OK\r\nx-grpc-web:1\r\n",
      )

      it_behaves_like 'serializes an exception'
    end

    context 'when the content type is not grpc-web+json' do
      let(:content_type) { ::GRPCWeb::ContentTypes::TEXT_CONTENT_TYPE }

      it_behaves_like(
        'generates a body with a payload frame',
         "\n\x03Noa",
      )
      it_behaves_like(
        'generates a body with a header frame',
         "grpc-status:0\r\ngrpc-message:OK\r\nx-grpc-web:1\r\n",
      )

      it_behaves_like 'serializes an exception'
    end
  end
end
