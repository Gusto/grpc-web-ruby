# frozen_string_literal: true

RSpec.describe ::GRPCWeb::ServiceClassValidator do
  subject(:validate) { described_class.validate(clazz) }

  context 'with a valid class' do
    let(:clazz) { TestHelloService }

    it 'does not raise' do
      expect { validate }.not_to raise_error
    end

    it 'returns true' do
      expect(validate).to be true
    end
  end

  context 'with an invalid class' do
    context 'which is not a service class' do
      let(:clazz) { Object }

      it 'raises an error' do
        expect { validate }.to raise_error(ArgumentError, "#{clazz} must 'include GenericService'")
      end
    end

    context 'which does not have rpc_descs' do
      let(:clazz) do
        Class.new do
          include ::GRPC::GenericService
        end
      end

      it 'raises an error' do
        expect { validate }
          .to raise_error(ArgumentError, "#{clazz} should specify some rpc descriptions")
      end
    end
  end
end
