module GRPCWeb
  module ServiceClassValidator
    def self.validate(clazz)
      unless clazz.include?(::GRPC::GenericService)
        raise(ArgumentError, "#{clazz} must 'include GenericService'")
      end
      if clazz.rpc_descs.size.zero?
        raise(ArgumentError, "#{clazz} should specify some rpc descriptions")
      end
    end
  end
end