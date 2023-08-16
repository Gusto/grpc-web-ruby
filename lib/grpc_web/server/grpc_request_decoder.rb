# frozen_string_literal: true

class GRPCWeb::GRPCRequestDecoder

  def self.decode(grpc_request)
    text_coder = ::GRPCWeb::TextCoder
    framing = ::GRPCWeb::RequestFraming
    serialization = ::GRPCWeb::MessageSerialization

    grpc_web_request = text_coder.decode_request(grpc_request)
    grpc_web_request = framing.unframe_request(grpc_web_request)
    serialization.deserialize_request(grpc_web_request)
  end
end
