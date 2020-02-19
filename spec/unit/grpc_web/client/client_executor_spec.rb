# frozen_string_literal: true

RSpec.describe ::GRPCWeb::ClientExecutor do
  describe '#request' do
    subject(:response) { described_class.request(uri, rpc_desc, params) }

    let(:url) { 'http://www.example.com' }
    let(:uri) { URI(url) }
    let(:rpc_desc) do
      GRPC::RpcDesc.new(
        :SayHello,
        HelloRequest,
        HelloResponse,
        :encode,
        :decode,
      )
    end
    let(:params) { {name: 'Noa'} }
    let(:expected_request_body) {"\u0000\u0000\u0000\u0000\u0005\n\u0003Noa"}
    let(:expected_headers) do
      {
        'Accept'=>GRPCWeb::ContentTypes::PROTO_CONTENT_TYPE,
        'Content-Type'=>GRPCWeb::ContentTypes::PROTO_CONTENT_TYPE,
      }
    end

    before do
      stub_request(:post, url).
        with(
         body: expected_request_body,
         headers: expected_headers).
        to_return(server_response)
    end

    context 'when the server returns a successful response' do
      let(:server_response) do
        {
          status: 200,
          body: "\x00\x00\x00\x00\v\n\tHello Noa\x80\x00\x00\x00.grpc-status:0\r\ngrpc-message:OK\r\nx-grpc-web:1\r\n".b,
        }
      end

      it 'returns the rpc_desc response object' do
        expect(response).to eq(HelloResponse.new(message: "Hello Noa"))
      end

      context 'with ssl' do
        let(:url) { 'https://www.example.com' }

        it 'returns the rpc_desc response object' do
          expect(response).to eq(HelloResponse.new(message: "Hello Noa"))
        end
      end
    end

    context 'when the server returns an error' do
      context 'http error' do
        let(:server_response) { { status: 500 } }

        it 'raises an error' do
          expect{ response }.to raise_error(RuntimeError)
        end
      end

      context 'grpc error' do
        let(:server_response) do
          {
            status: 200,
            body: "\x80\x00\x00\x008grpc-status:#{GRPC::Core::StatusCodes::INVALID_ARGUMENT}\r\ngrpc-message:Test message\r\nx-grpc-web:1\r\n",
          }
        end

        it 'raises an error' do
          expect{ response }.to raise_error(GRPC::InvalidArgument)
        end
      end
    end
  end
end
