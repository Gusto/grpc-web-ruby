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
        'Content-Type' => GRPCWeb::ContentTypes::PROTO_CONTENT_TYPE
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

      context 'with custom header' do
        subject(:response) { described_class.request(request_uri, rpc_desc, params, custom_header) }
        let(:custom_header) { {'Custom-header' => 'Meow meow'} }
        let(:expected_headers) do
          {
            'Accept' => GRPCWeb::ContentTypes::PROTO_CONTENT_TYPE,
            'Content-Type' => GRPCWeb::ContentTypes::PROTO_CONTENT_TYPE,
            'Custom-header' => 'Meow meow',
          }
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
      [
        { server_http_response_code: 400, expected_grpc_error: GRPC::Internal },
        { server_http_response_code: 401, expected_grpc_error: GRPC::Unauthenticated },
        { server_http_response_code: 403, expected_grpc_error: GRPC::PermissionDenied },
        { server_http_response_code: 404, expected_grpc_error: GRPC::Unimplemented },
        { server_http_response_code: 429, expected_grpc_error: GRPC::Unavailable },
        { server_http_response_code: 502, expected_grpc_error: GRPC::Unavailable },
        { server_http_response_code: 503, expected_grpc_error: GRPC::Unavailable },
        { server_http_response_code: 504, expected_grpc_error: GRPC::Unavailable },
        { server_http_response_code: 500, expected_grpc_error: GRPC::Unknown },
        { server_http_response_code: 200, expected_grpc_error: GRPC::Unknown },
        { server_http_response_code: 200, expected_grpc_error: GRPC::Internal, body: 'something' },
      ].each do |server_http_response_code:, expected_grpc_error:, body: nil|
        context "HTTP error #{server_http_response_code}" do
          let(:server_response) { { status: server_http_response_code, body: body } }

          it "raises the corresponding error #{expected_grpc_error}" do
            expect { response }.to raise_error(expected_grpc_error)
          end
        end
      end

      context 'which is a grpc error' do
        let(:server_response) do
          {
            status: 200,
            body:
              "\x80\x00\x00\x00Wgrpc-status:#{GRPC::Core::StatusCodes::INVALID_ARGUMENT}"\
              "\r\ngrpc-message:Test message\r\nx-grpc-web:1"\
              "\r\nuser-role-id:123\r\nuser-id:456\r\n",
          }
        end

        it 'raises an error' do
          expect { response }.to raise_error(GRPC::InvalidArgument) do |exception|
            expect(exception.metadata).to eq('user-role-id' => '123', 'user-id' => '456')
          end
        end
      end
    end

    context 'with a network error' do
      before { allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED) }

      let(:server_stub) {}

      it 'raises an unavailable error' do
        expect { response }.to raise_error(GRPC::Unavailable)
      end
    end
  end
end
