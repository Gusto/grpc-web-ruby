# frozen_string_literal: true

class GRPCWeb::GRPCResponseEncoder

  def self.encode(response)
    text_coder = ::GRPCWeb::TextCoder
    framing = ::GRPCWeb::RequestFraming
    serialization = ::GRPCWeb::MessageSerialization

    grpc_web_response = serialization.serialize_response(response)
    grpc_web_response = framing.frame_response(grpc_web_response)
    text_coder.encode_response(grpc_web_response)
  end
end
