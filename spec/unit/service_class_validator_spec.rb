RSpec.describe ::GRPCWeb::ServiceClassValidator do
  describe 'validation' do
    context 'given a class' do
      subject { described_class.validate(clazz) }

      context 'valid class' do
        let(:clazz) { TestHelloService }
        it 'does not raise' do
          expect{ subject }.to_not raise_error
        end
      end

      context 'invalid class' do
        context 'not a service class' do
          let(:clazz) { Object }
          it 'raises an error' do
            expect{ subject }.to raise_error(ArgumentError, "#{clazz} must 'include GenericService'")
          end
        end

        context 'class without rpc_descs' do
          let(:clazz) do
            class EmptyClass
              include ::GRPC::GenericService
            end
          end
          it 'raises an error' do
            expect{ subject }.to raise_error(ArgumentError, "#{clazz} should specify some rpc descriptions")
          end
        end
      end
    end
  end
end
