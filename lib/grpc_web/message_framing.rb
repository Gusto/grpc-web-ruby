# frozen_string_literal: true

require 'grpc_web/message_frame'

module GRPCWeb
  # GRPC Web uses a simple 5 byte framing scheme. The first byte represents
  # flags indicating what type of frame this is. The next 4 bytes indicate the
  # byte length of the frame body.
  module MessageFraming
    class << self
      def frame_content(content, frame_type = ::GRPCWeb::MessageFrame::PAYLOAD_FRAME_TYPE)
        length_bytes = [content.bytesize].pack('N')
        "#{frame_type.chr}#{length_bytes}#{content}"
      end

      def unframe_content(content)
        frames = []
        remaining_content = content
        until remaining_content.empty?
          msg_length = remaining_content[1..4].unpack1('N')
          raise 'Invalid message length' if msg_length <= 0

          frame_end = 5 + msg_length
          frames << ::GRPCWeb::MessageFrame.new(
            remaining_content[0].bytes[0],
            remaining_content[5...frame_end],
          )
          remaining_content = remaining_content[frame_end..-1]
        end
        frames
      end
    end
  end
end
