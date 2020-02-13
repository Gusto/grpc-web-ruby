require 'grpc_web/message_framing'

RSpec.describe GRPCWeb::MessageFraming do
  describe '#frame_content' do
    let(:content) {'some content'}
    subject(:framed_content) { described_class.frame_content(content, frame_type) }

    context 'when the frame type is unspecified' do
      subject(:framed_content) { described_class.frame_content(content) }
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

  end
end