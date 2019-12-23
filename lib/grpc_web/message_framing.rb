# frozen_string_literal: true

require 'grpc_web/message_frame'

module GRPCWeb
  # GRPC Web uses a simple 5 byte framing scheme. The first byte represents
  # flags indicating what type of frame this is. The next 4 bytes indicate the
  # byte length of the frame body.
  module MessageFraming
    class << self
      def frame_content(content, flags = "\x00")
        length_bytes = [content.bytesize].pack('N')
        "#{flags}#{length_bytes}#{content}"
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

      # If needed, trailers can be appended to the response as a 2nd
      # base64 encoded string with independent framing.
      def generate_trailers
        frame_response([
          'grpc-status:0',
          'grpc-message:OK',
          'x-grpc-web:1',
        ].join("\r\n"), "\x80")
      end
    end
  end
end
