# frozen_string_literal: true

require 'grpc_web/grpc_web_response'
require 'grpc_web/grpc_web_request'
require 'grpc_web/message_frame'

module GRPCWeb
  # GRPC Web uses a simple 5 byte framing scheme. The first byte represents
  # flags indicating what type of frame this is. The next 4 bytes indicate the
  # byte length of the frame body.
  module MessageFraming
    class << self
      def unframe_request(request)
        frames = unframe_content(request.body)
        ::GRPCWeb::GRPCWebRequest.new(
          request.service, request.service_method, request.content_type, frames)
      end

      def frame_response(response)
        framed = response.body.map do |frame|
          frame_content(frame.body, frame.frame_type)
        end.join
        ::GRPCWeb::GRPCWebResponse.new(response.content_type, framed)
      end

      def frame_content(content, frame_type = ::GRPCWeb::MessageFrame::PAYLOAD_FRAME_TYPE)
        length_bytes = [content.bytesize].pack('N')
        "#{frame_type.chr}#{length_bytes}#{content}"
      end

      def unframe_content(content)
        frames = []
        remaining_content = content
        while remaining_content.length > 0
          msg_length = remaining_content[1..4].unpack("N").first
          raise "Invalid message length" if msg_length <= 0

          frame_end = 5 + msg_length
          frames << ::GRPCWeb::MessageFrame.new(remaining_content[0].bytes[0], remaining_content[5...frame_end])
          remaining_content = remaining_content[frame_end..-1]
        end
        frames
      end
    end
  end
end
