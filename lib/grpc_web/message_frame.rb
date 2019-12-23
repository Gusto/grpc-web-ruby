# frozen_string_literal: true

module GRPCWeb
  PAYLOAD_FRAME_TYPE = "\x00"
  HEADER_FRAME_TYPE = "\x80"

  MessageFrame = Struct.new(:frame_type, :body)
end
