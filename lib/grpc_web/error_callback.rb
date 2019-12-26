# frozen_string_literal: true

module GRPCWeb
  class << self
    NOOP_ON_ERROR = Proc.new {|ex, service, service_method| }

    def on_error(&block)
      if block_given?

        unless block.parameters.length == 3
          raise ArgumentError, 'callback must accept (exception, service, service_method)'
        end

        self.on_error_callback = block
      else
        on_error_callback || NOOP_ON_ERROR
      end
    end

    private

    attr_accessor :on_error_callback
  end
end
