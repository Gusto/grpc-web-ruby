require 'grpc_web/content_types'
require 'grpc_web/rack_handler'

RSpec.describe(::GRPCWeb::RackHandler) do
  describe '#call' do
    let(:service) { double('service') }
    let(:service_method) { double('service method') }
    subject { described_class.call(service, service_method, env) }

    # Request
    let(:path_info) { 'request/path' }
    let(:request_method) { 'POST' }
    let(:content_type) { ::GRPCWeb::ContentTypes::DEFAULT_CONTENT_TYPE }
    let(:accept_header) { '*/*' }
    let(:request_body) { 'request body' }
    let(:env) {
      {
        'PATH_INFO' => path_info,
        'REQUEST_METHOD' => request_method,
        'CONTENT_TYPE' => content_type,
        'HTTP_ACCEPT' => accept_header,
        'rack.input' => StringIO.new(request_body),
      }
    }

    # Response
    let(:response_content_type) { 'text' }
    let(:response_body) { 'body' }
    let(:response) { ::GRPCWeb::GRPCWebResponse.new(response_content_type, response_body) }

    before do
      allow(::GRPCWeb::GRPCRequestProcessor).to receive(:process).and_return(response)
    end

    context 'valid request' do
      it 'returns a 200' do
        expect(subject).to eq([
                                200,
                                { 'Content-Type' => response_content_type },
                                [response_body]
                              ])
      end

      it 'calls the request processor with the modified request' do
        expect(::GRPCWeb::GRPCRequestProcessor).to receive(:process).with(::GRPCWeb::GRPCWebRequest.new(
                                                                            service,
                                                                            service_method,
                                                                            content_type,
                                                                            accept_header,
                                                                            request_body
                                                                          ))
        subject
      end
    end

    context 'invalid request' do
      context 'unsupported http method' do
        let(:request_method) { 'PUT' }
        it 'returns a 404' do
          expect(subject).to eq([
                                  404,
                                  { 'Content-Type' => 'text/plain', "X-Cascade" => "pass" },
                                  ["Not Found: #{path_info}"]
                                ])
        end
      end

      context 'unsupported content type' do
        let(:content_type) { "text/plain" }
        it 'returns a 415' do
          expect(subject).to eq([
                                  415,
                                  { 'Content-Type' => 'text/plain' },
                                  ['Unsupported Media Type: Invalid Content-Type or Accept header']
                                ])
        end
      end

      context 'unsupported accept header' do
        let(:accept_header) { "text/plain" }
        it 'returns a 415' do
          expect(subject).to eq([
                                  415,
                                  { 'Content-Type' => 'text/plain' },
                                  ['Unsupported Media Type: Invalid Content-Type or Accept header']
                                ])
        end
      end

      context 'unsupported accept header' do
        let(:accept_header) { "text/plain" }
        it 'returns a 415' do
          expect(subject).to eq([
                                  415,
                                  { 'Content-Type' => 'text/plain' },
                                  ['Unsupported Media Type: Invalid Content-Type or Accept header']
                                ])
        end
      end

      context 'invalid format' do
        let(:error_message) { 'error while parsing' }
        before do
          allow(::GRPCWeb::GRPCRequestProcessor).to receive(:process)
            .and_raise(Google::Protobuf::ParseError, error_message)
        end

        it 'returns a 422' do
          expect(subject).to eq([
                                  422,
                                  { 'Content-Type' => 'text/plain' },
                                  ["Invalid request format: #{error_message}"]
                                ])
        end
      end
    end

    context 'server error' do
      before do
        allow(::GRPCWeb::GRPCRequestProcessor).to receive(:process)
          .and_raise(StandardError, 'something internal went wrong')
      end

      it 'returns a 500' do
        expect(subject).to eq([
                                500,
                                { 'Content-Type' => 'text/plain' },
                                ['Request failed with an unexpected error.']
                              ])
      end
    end
  end
end
