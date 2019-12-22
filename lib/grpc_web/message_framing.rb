# frozen_string_literal: true

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
        raise "Invalid request format" if content[0] != "\x00"

        msg_length = content[1..4].unpack("N").first
        raise "Invalid message length" if msg_length <= 0

        content[5..(5 + msg_length)]
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
