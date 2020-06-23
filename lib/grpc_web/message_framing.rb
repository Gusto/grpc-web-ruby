# frozen_string_literal: true

require 'grpc_web/message_frame'

# Placeholder
module GRPCWeb::MessageFraming
  class << self
    def pack_frames(frames)
      frames.map do |frame|
        length_bytes = [frame.body.bytesize].pack('N')
        "#{frame.frame_type.chr}#{length_bytes}#{frame.body}"
      end.join
    end

    def unpack_frames(content)
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
    rescue StandardError => e
      raise ::GRPC::Internal, e.message
    end
  end
end
