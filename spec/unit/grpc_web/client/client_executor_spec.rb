# frozen_string_literal: true

require 'grpc_web/client/client_executor'
require 'grpc/generic/rpc_desc'
require_relative '../../../../spec/pb-ruby/hello_services_pb'

RSpec.describe ::GRPCWeb::ClientExecutor do
  describe '#request' do
    subject(:response) { described_class.request(request_uri, rpc_desc, params) }

    let(:server_url) { 'http://www.example.com' }
    let(:request_uri) { URI(server_url) }
    let(:rpc_desc) do
      GRPC::RpcDesc.new(
        :SayHello,
        HelloRequest,
        HelloResponse,
        :encode,
        :decode,
      )
    end
    let(:params) { { name: 'Noa' } }
    let(:expected_request_body) { "\u0000\u0000\u0000\u0000\u0005\n\u0003Noa" }
    let(:expected_headers) do
      {
        'Accept' => GRPCWeb::ContentTypes::PROTO_CONTENT_TYPE,
        'Content-Type' => GRPCWeb::ContentTypes::PROTO_CONTENT_TYPE,
      }
    end

    let!(:server_stub) do
      stub_request(:post, server_url).to_return(server_response)
    end

    context 'when the server returns a successful response' do
      let(:server_response) do
        {
          status: 200,
          body:
            "\x00\x00\x00\x00\v\n\tHello Noa"\
            "\x80\x00\x00\x00.grpc-status:0\r\ngrpc-message:OK\r\nx-grpc-web:1\r\n",
        }
      end
      let(:expected_response) { HelloResponse.new(message: 'Hello Noa') }

      it 'returns the rpc_desc response object' do
        expect(response).to eq(expected_response)
      end

      it 'sends the correct headers and body' do
        response
        assert_requested(
          server_stub.with(
            headers: expected_headers,
            body: expected_request_body,
          ),
        )
      end

      context 'with ssl' do
        let(:server_url) { 'https://www.example.com' }

        it 'returns the rpc_desc response object' do
          expect(response).to eq(expected_response)
        end
      end

      context 'with a username' do
        let(:username) { 'noa' }
        let(:request_uri) { URI("http://#{username}@www.example.com") }

        it 'sends the auth info in the request' do
          expect(response).to eq(expected_response)
        end

        it 'sends the correct headers body and auth information' do
          response
          assert_requested(
            server_stub.with(
              headers: expected_headers,
              body: expected_request_body,
              basic_auth: [username],
            ),
          )
        end

        context 'and a password' do
          let(:password) { 'passthesauce' }
          let(:request_uri) { URI("http://#{username}:#{password}@www.example.com") }

          it 'sends the auth info in the request' do
            expect(response).to eq(expected_response)
          end

          it 'sends the correct headers body and auth information' do
            response
            assert_requested(
              server_stub.with(
                headers: expected_headers,
                body: expected_request_body,
                basic_auth: [username, password],
              ),
            )
          end
        end
      end
    end

    context 'when the server returns an error' do
      context 'which is an http error' do
        let(:server_response) { { status: 500 } }

        it 'raises an error' do
          expect { response }.to raise_error(GRPC::Unavailable)
        end
      end

      context 'which is a grpc error' do
        let(:server_response) do
          {
            status: 200,
            body:
              "\x80\x00\x00\x008grpc-status:#{GRPC::Core::StatusCodes::INVALID_ARGUMENT}"\
              "\r\ngrpc-message:Test message\r\nx-grpc-web:1\r\n",
          }
        end

        it 'raises an error' do
          expect { response }.to raise_error(GRPC::InvalidArgument)
        end
      end
    end
  end
end
