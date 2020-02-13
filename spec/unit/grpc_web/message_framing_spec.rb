# frozen_string_literal: true

require 'grpc_web/message_framing'

RSpec.describe GRPCWeb::MessageFraming do
  let(:unframed_data) { 'some content' }
  let(:payload_framed_data) { "\x00\x00\x00\x00\fsome content".b }
  let(:header_framed_data) { "\x80\x00\x00\x00\fsome content".b }
  let(:unpacked_frames) {
    [
      ::GRPCWeb::MessageFrame.header_frame('data in the header'),
      ::GRPCWeb::MessageFrame.payload_frame('data in the first frame'),
      ::GRPCWeb::MessageFrame.payload_frame('data in the second frame')
    ]
  }
  let(:packed_frames) do
    string = "\x80\x00\x00\x00\x12data in the header" +
      "\x00\x00\x00\x00\x17data in the first frame" +
      "\x00\x00\x00\x00\x18data in the second frame"
    string.b
  end
  describe '#frame_content' do
    subject { described_class.pack_frames(unpacked_frames) }

    it { is_expected.to eq packed_frames }
  end

  describe '#unframe_content' do
    subject { described_class.unpack_frames(packed_frames) }

    it { is_expected.to eq unpacked_frames }
  end
end
