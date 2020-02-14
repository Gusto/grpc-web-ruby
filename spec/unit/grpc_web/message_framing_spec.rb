# frozen_string_literal: true

require 'grpc_web/message_framing'

RSpec.describe GRPCWeb::MessageFraming do
  let(:unpacked_frames) do
    [
      ::GRPCWeb::MessageFrame.header_frame("data in the header"),
      ::GRPCWeb::MessageFrame.payload_frame("data in the \u1f61d first frame"),
      ::GRPCWeb::MessageFrame.payload_frame("data in the second frame"),
    ]
  end
  let(:packed_frames) do
    string = "\x80\x00\x00\x00\x12data in the header" \
             "\x00\x00\x00\x00\x1Cdata in the \u1f61d first frame" \
             "\x00\x00\x00\x00\x18data in the second frame"
    string.b # treat string as a byte string
  end

  describe '#pack_frames' do
    subject { described_class.pack_frames(unpacked_frames) }

    it { is_expected.to eq packed_frames }
  end

  describe '#unpack_frames' do
    subject { described_class.unpack_frames(packed_frames) }

    it { is_expected.to eq unpacked_frames }
  end

  describe 'pack and unpack frames' do
    subject { described_class.unpack_frames(described_class.pack_frames(unpacked_frames)) }

    it { is_expected.to eq unpacked_frames }
  end

  describe 'unpack and pack frames' do
    subject { described_class.pack_frames(described_class.unpack_frames(packed_frames)) }

    it { is_expected.to eq packed_frames }
  end
end
