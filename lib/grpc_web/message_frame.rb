# frozen_string_literal: true

module GRPCWeb
  class MessageFrame
    PAYLOAD_FRAME_TYPE = 0 # String: "\x00"
    HEADER_FRAME_TYPE = 128 # String: "\x80"

    def self.payload_frame(body)
      new(PAYLOAD_FRAME_TYPE, body)
    end

    def self.header_frame(body)
      new(HEADER_FRAME_TYPE, body)
    end

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
