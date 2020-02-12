# frozen_string_literal: true

require 'grpc_web/grpc_web_response'
require 'grpc_web/grpc_web_request'
require 'grpc_web/message_framing'

module GRPCWeb
  # GRPC Web uses a simple 5 byte framing scheme. The first byte represents
  # flags indicating what type of frame this is. The next 4 bytes indicate the
  # byte length of the frame body.
  module RequestFraming
    class << self
      def unframe_request(request)
        frames = MessageFraming::unframe_content(request.body)
        ::GRPCWeb::GRPCWebRequest.new(
          request.service, request.service_method, request.content_type, request.accept, frames,
          )
      end

      def frame_response(response)
        framed = response.body.map do |frame|
          MessageFraming::frame_content(frame.body, frame.frame_type)
        end.join
        ::GRPCWeb::GRPCWebResponse.new(response.content_type, framed)
      end
    end
  end
end
