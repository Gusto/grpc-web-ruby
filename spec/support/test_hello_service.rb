# frozen_string_literal: true

require 'hello_services_pb'

class TestHelloService < HelloService::Service
  def say_hello(request, _call = nil)
    HelloResponse.new(message: "Hello #{request.name}")
  end
  def say_nothing(request, _call = nil)
    EmptyResponse.new
  end
end
