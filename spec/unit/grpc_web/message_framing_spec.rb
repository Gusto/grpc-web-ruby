# frozen_string_literal: true

require 'grpc_web/message_framing'

RSpec.describe GRPCWeb::MessageFraming do
  let(:unframed_content) { 'some content' }
  let(:framed_content) { "\x80\x00\x00\x00\fsome content".b }

  describe '#frame_content' do
    subject(:framed_content) { described_class.frame_content(unframed_content, frame_type) }

    context 'when the frame type is unspecified' do
      subject(:framed_content) { described_class.frame_content(unframed_content) }

      it 'returns framed content' do
        expect(framed_content).to eq "\x00\x00\x00\x00\fsome content".b
      end
    end

    context 'when the frame type is payload' do
      subject(:frame_type) { ::GRPCWeb::MessageFrame::PAYLOAD_FRAME_TYPE }

      it 'returns framed content' do
        expect(framed_content).to eq "\x00\x00\x00\x00\fsome content".b
      end
    end

    context 'when the frame type is header' do
      subject(:frame_type) { ::GRPCWeb::MessageFrame::HEADER_FRAME_TYPE }

      it 'returns framed content' do
        expect(framed_content).to eq "\x80\x00\x00\x00\fsome content".b
      end
    end
  end

  describe '#unframe_content' do
    let(:content) { "\x80\x00\x00\x00\fsome content".b }
    subject(:unframed_content) { described_class.unframe_content(framed_content) }

    it 'returns unframed content' do
      expect(unframed_content).to eq unframed_content
    end
  end
end
