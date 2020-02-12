# frozen_string_literal: true

require 'grpc_web/error_callback'

RSpec.describe 'GRPCWeb.on_error' do
  describe 'setting the callback' do
    subject { GRPCWeb.on_error(&callback) }

    let(:callback) { proc { |a, b, c| } }

    it 'returns the callback' do
      expect(subject).to eq callback
    end

    it 'saves the callback for later' do
      subject
      expect(GRPCWeb.on_error).to eq callback
    end

    context 'with a callback that accepts the wrong number of parameters' do
      let(:callback) { proc { |a, b| } }

      it 'raises an error' do
        expect { subject }.to raise_error(
          ArgumentError, 'callback must accept (exception, service, service_method)',
        )
      end
    end
  end

  describe 'calling the callback' do
    subject { ::GRPCWeb.on_error.call(*callback_parameters) }

    let(:callback) { proc { |a, b, c| } }
    let(:callback_parameters) { %w[a b c] }

    context 'before setting the a callback' do
      it 'is a no-op' do
        expect(callback).not_to receive(:call)
        subject
      end
    end

    context 'after setting a callback' do
      before { GRPCWeb.on_error(&callback) }

      it 'calls the callback' do
        expect(callback).to receive(:call).with(*callback_parameters)
        subject
      end
    end
  end
end
