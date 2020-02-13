# # frozen_string_literal: true
#
# require 'grpc_web/message_framing'
#
# RSpec.describe GRPCWeb::MessageFraming do
#   let(:unframed_data) { 'some content' }
#   let(:payload_framed_data) { "\x00\x00\x00\x00\fsome content".b }
#   let(:header_framed_data) { "\x80\x00\x00\x00\fsome content".b }
#
#   describe '#frame_content' do
#     subject(:framed_content) { described_class.frame_content(unframed_data, frame_type) }
#
#     context 'when the frame type is unspecified' do
#       subject(:framed_content) { described_class.frame_content(unframed_data) }
#
#       it 'returns framed content' do
#         expect(framed_content).to eq payload_framed_data
#       end
#     end
#
#     context 'when the frame type is payload' do
#       subject(:frame_type) { ::GRPCWeb::MessageFrame::PAYLOAD_FRAME_TYPE }
#
#       it 'returns framed content' do
#         expect(framed_content).to eq payload_framed_data
#       end
#     end
#
#     context 'when the frame type is header' do
#       subject(:frame_type) { ::GRPCWeb::MessageFrame::HEADER_FRAME_TYPE }
#
#       it 'returns framed content' do
#         expect(framed_content).to eq header_framed_data
#       end
#     end
#   end
#
#   describe '#unframe_content' do
#     subject(:unframed_content) { described_class.unframe_content(payload_framed_data) }
#
#     it 'returns unframed content' do
#       expect(unframed_content).to eq unframed_data
#     end
#   end
# end
