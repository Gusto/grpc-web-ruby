# frozen_string_literal: true

module GRPCWeb
  GRPCWebCall = Struct.new(
    :request,
    :metadata,
    :metadata_received,
    :metadata_sent,
    :metadata_to_send,
  )
end

