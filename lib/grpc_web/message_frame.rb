# frozen_string_literal: true

module GRPCWeb
  class MessageFrame
    PAYLOAD_FRAME_TYPE_STR = "\x00"
    PAYLOAD_FRAME_TYPE = PAYLOAD_FRAME_TYPE_STR.bytes[0]
    HEADER_FRAME_TYPE_STR = "\x80"
    HEADER_FRAME_TYPE = HEADER_FRAME_TYPE_STR.bytes[0]

    attr_accessor :frame_type, :body

    def initialize(frame_type, body)
      self.frame_type = frame_type
      self.body = body
    end

    def payload?
      frame_type == PAYLOAD_FRAME_TYPE
    end

    def header?
      frame_type == HEADER_FRAME_TYPE
    end
  end
end
