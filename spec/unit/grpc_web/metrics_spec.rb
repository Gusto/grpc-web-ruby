# frozen_string_literal: true

require 'grpc_web/metrics'

RSpec.describe GRPCWeb::Metrics do
  class DummyStatsD
    def increment(m, *args, &block)
      # something
    end
  end

  class DummyDogStatsD
    def increment(name, opts = {})
      # something
    end
  end

  old_val = nil

  before do
    old_val = GRPCWeb.metrics
  end

  after do
    GRPCWeb.metrics = old_val
  end

  describe '.metrics' do
    context 'defaults to GRPCWeb::Metrics empty' do
      it 'successfully' do
        expect(GRPCWeb.metrics).to be_kind_of(GRPCWeb::Metrics::Empty)
      end
    end

    context 'responds to a custom object being assigned to' do
      it 'successfully' do
        instance = DummyStatsD.new
        GRPCWeb.metrics = instance

        expect(instance).to receive(:increment).with('foo', 1)
        GRPCWeb.metrics.increment('foo', 1)
      end
    end
  end

  describe '.metrics=' do
    context 'assigns passed object' do
      it 'successfully' do
        GRPCWeb.metrics = DummyStatsD.new

        expect(GRPCWeb.metrics).to be_kind_of(DummyStatsD)
      end
    end
  end

  describe '.dogstatsd=' do
    context 'assigns passed object' do
      it 'successfully' do
        GRPCWeb.dogstatsd = DummyDogStatsD.new

        expect(GRPCWeb.metrics).to be_kind_of(GRPCWeb::Metrics::DogStatsD)
        expect(GRPCWeb.metrics.statsd).to be_kind_of(DummyDogStatsD)
      end
    end

    context 'responds to a custom dogstatsdobject being assigned to' do
      it 'successfully with metric name prefixed' do
        instance = DummyDogStatsD.new
        GRPCWeb.dogstatsd = instance

        expect(instance).to receive(:increment).with('grpc_web_ruby.foo', foo: 'bar')
        GRPCWeb.metrics.increment('foo', foo: 'bar')
      end
    end
  end

  describe '::Empty' do
    context 'does not raise exception' do
      it 'when a undefined method is called' do
        result = GRPCWeb.metrics.increment('foo')
        expect(result).to eq(nil)
      end

      it 'when a undefined method is called with arguments' do
        expect(GRPCWeb.metrics).to receive(:method_missing).and_call_original

        expect(GRPCWeb.metrics.decrement('foo', 1, {}, 'bar')).to eq(nil)
      end

      it 'when a undefined method is called with arguments and block' do
        expect(GRPCWeb.metrics).to receive(:method_missing).and_call_original

        expect(GRPCWeb.metrics.decrement('foo', 1, {}, 'bar') { 'block' }).to eq('block')
      end
    end
  end
end
