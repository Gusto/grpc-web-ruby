# frozen_string_literal: true

module GRPCWeb
  PAYLOAD_FRAME_TYPE = "\x00".bytes[0]
  HEADER_FRAME_TYPE = "\x80".bytes[0]

  MessageFrame = Struct.new(:frame_type, :body)
end
