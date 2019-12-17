# frozen_string_literal: true

require 'hello_services_pb'

class TestHelloService < HelloService::Service
  def say_hello(request, _call = nil)
    return HelloResponse.new(message: "Hello #{request.name}")
  end
end
