# frozen_string_literal: true

require 'grpc_web/server/text_coder'

RSpec.describe GRPCWeb::TextCoder do
  describe '#decode_request' do
    subject(:decoded_request) { described_class.decode_request(request) }

    let(:request) do
      ::GRPCWeb::GRPCWebRequest.new(
        service,
        service_method,
        content_type,
        accept,
        body,
      )
    end
    let(:service) { instance_double(TestHelloService) }
    let(:service_method) { :SayHello }
    let(:accept) { '*/*' }
    let(:chunk_contents) { ['Hello Noa!', 'this is another chunk'] }

    context('when the content type is non encoded') do
      let(:content_type) { ::GRPCWeb::ContentTypes::DEFAULT_CONTENT_TYPE }
      let(:body) { 'Hi Noa!' }

      it 'is a no-op' do
        expect(decoded_request).to eq request
      end
    end

    context('when the content tyep is encoded') do
      let(:content_type) { ::GRPCWeb::ContentTypes::TEXT_CONTENT_TYPE }
      let(:body_content) { 'Hi Noa!' }
      let(:body) { Base64.strict_encode64(body_content) }

      it 'decodes the request body' do
        expect(decoded_request.body).to eq body_content
      end

      it 'does not change anything else besides the body' do
        expect([
          decoded_request.service,
          decoded_request.service_method,
          decoded_request.content_type,
          decoded_request.accept,
        ]).to eq [
          request.service,
          request.service_method,
          request.content_type,
          request.accept,
        ]
      end

      context 'with several chunks' do
        let(:chunk_contents) { ['Hello Noa!', 'this is another chunk', 'and this too'] }
        let(:body) { chunk_contents.map { |chunk| Base64.strict_encode64(chunk) }.join }

        it 'decodes the request body' do
          expect(decoded_request.body).to eq chunk_contents.join
        end
      end
    end
  end

  describe '#encode_response' do
    subject(:encoded_response) { described_class.encode_response(response) }

    let(:response_body) { 'body' }
    let(:response) { ::GRPCWeb::GRPCWebResponse.new(response_content_type, response_body) }

    context('non encoded content type') do
      let(:response_content_type) { ::GRPCWeb::ContentTypes::DEFAULT_CONTENT_TYPE }

      it 'is a no-op' do
        expect(encoded_response).to eq response
      end
    end

    context('encoded content type') do
      let(:response_content_type) { ::GRPCWeb::ContentTypes::TEXT_CONTENT_TYPE }

      it 'encodes the response body' do
        expect(encoded_response.body).to eq Base64.strict_encode64(response_body)
      end

      it 'does not change anything else besides the body' do
        expect(encoded_response.content_type).to eq response_content_type
      end
    end
  end
end
